import AVFoundation
import Flutter
import UIKit

public class StilloraVideoEnginePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var progressSink: FlutterEventSink?
  private var isCancelled = false
  private let workQueue = DispatchQueue(label: "app.stillora.video_engine", qos: .userInitiated)

  // MARK: - Registration

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "stillora_video_engine",
      binaryMessenger: registrar.messenger())
    let instance = StilloraVideoEnginePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let progressChannel = FlutterEventChannel(
      name: "stillora_video_engine/progress",
      binaryMessenger: registrar.messenger())
    progressChannel.setStreamHandler(instance)
  }

  // MARK: - Progress stream

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    progressSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    progressSink = nil
    return nil
  }

  // MARK: - Method handling

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "exportVideo":
      guard let args = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_arguments", message: "Export arguments were missing.", details: nil))
        return
      }
      isCancelled = false
      workQueue.async { [weak self] in
        self?.runExport(args: args, result: result)
      }
    case "cancelExport":
      isCancelled = true
      result(nil)
    case "clearTemporaryFiles":
      clearTemporaryFiles()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Export

  private enum EngineError: Error { case render, write, export, cancelled, missingSource }

  private func runExport(args: [String: Any], result: @escaping FlutterResult) {
    let imagePath = args["imagePath"] as? String ?? ""
    let imagePaths = (args["imagePaths"] as? [String]) ?? []
    let audioPath = args["audioPath"] as? String
    let duration = max(1, args["durationSeconds"] as? Int ?? 10)
    let width = evenDimension(args["width"] as? Int ?? 1080)
    let height = evenDimension(args["height"] as? Int ?? 1920)
    let fill = (args["resizeMode"] as? String ?? "fit") == "fill"

    do {
      let outputURL = try makeOutputURL()

      if isVideoFile(imagePath) {
        try exportFromVideo(
          sourceURL: URL(fileURLWithPath: imagePath), audioPath: audioPath, width: width,
          height: height, duration: duration, fill: fill, outputURL: outputURL)
      } else {
        let paths = imagePaths.isEmpty ? [imagePath] : imagePaths
        try exportFromImage(
          imagePaths: paths, audioPath: audioPath, width: width, height: height,
          duration: duration, fill: fill, outputURL: outputURL)
      }

      emit(stage: "done", percentage: 1.0, message: "Saved")
      result([
        "outputPath": outputURL.path,
        "width": width,
        "height": height,
        "durationSeconds": duration,
      ])
    } catch EngineError.cancelled {
      result(
        FlutterError(code: "cancelled", message: "Export was cancelled.", details: nil))
    } catch {
      result(
        FlutterError(
          code: "export_failed", message: error.localizedDescription, details: nil))
    }
  }

  // MARK: - Image source

  private func exportFromImage(
    imagePaths: [String], audioPath: String?, width: Int, height: Int, duration: Int, fill: Bool,
    outputURL: URL
  ) throws {
    emit(stage: "preparingImage", percentage: 0.05, message: "Preparing image")

    // Render every selected image into a pixel buffer. Unreadable images are
    // skipped so one bad file does not abort the whole slideshow.
    var buffers: [CVPixelBuffer] = []
    for path in imagePaths {
      guard let rawImage = UIImage(contentsOfFile: path) else { continue }
      let image = normalizedImage(rawImage)
      guard let buffer = pixelBuffer(from: image, width: width, height: height, fill: fill)
      else { continue }
      buffers.append(buffer)
    }
    guard !buffers.isEmpty else { throw EngineError.missingSource }

    // When there is audio we render to a silent intermediate, then mux.
    let needsAudio = (audioPath != nil) && FileManager.default.fileExists(atPath: audioPath!)
    let videoURL = needsAudio ? try makeTempURL() : outputURL

    try writeSlideshow(
      buffers: buffers, width: width, height: height, duration: duration, to: videoURL)

    if needsAudio {
      emit(stage: "mergingAudio", percentage: 0.85, message: "Merging audio")
      try mux(
        videoURL: videoURL, audioURL: URL(fileURLWithPath: audioPath!), duration: duration,
        to: outputURL)
      try? FileManager.default.removeItem(at: videoURL)
    }
    emit(stage: "savingVideo", percentage: 0.95, message: "Saving")
  }

  /// Writes a still video that cycles through `buffers`, giving each image an
  /// equal share of the total duration. A single buffer produces a static clip.
  private func writeSlideshow(
    buffers: [CVPixelBuffer], width: Int, height: Int, duration: Int, to url: URL
  ) throws {
    try? FileManager.default.removeItem(at: url)
    let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
    let settings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height,
    ]
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    input.expectsMediaDataInRealTime = false
    let attrs: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
      kCVPixelBufferWidthKey as String: width,
      kCVPixelBufferHeightKey as String: height,
    ]
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: input, sourcePixelBufferAttributes: attrs)

    guard writer.canAdd(input) else { throw EngineError.write }
    writer.add(input)
    guard writer.startWriting() else { throw writer.error ?? EngineError.write }
    writer.startSession(atSourceTime: .zero)

    let fps: Int32 = 30
    let totalFrames = max(1, Int(duration) * Int(fps))
    let count = buffers.count
    var frame = 0

    while frame < totalFrames {
      if isCancelled {
        input.markAsFinished()
        writer.cancelWriting()
        throw EngineError.cancelled
      }
      if input.isReadyForMoreMediaData {
        let bufferIndex = min(count - 1, frame * count / totalFrames)
        let time = CMTime(value: CMTimeValue(frame), timescale: fps)
        if !adaptor.append(buffers[bufferIndex], withPresentationTime: time) {
          throw writer.error ?? EngineError.write
        }
        frame += 1
        if frame % 15 == 0 {
          emit(
            stage: "generatingVideo",
            percentage: 0.1 + (Double(frame) / Double(totalFrames)) * 0.7,
            message: "Generating video")
        }
      } else {
        usleep(4000)
      }
    }

    input.markAsFinished()
    let semaphore = DispatchSemaphore(value: 0)
    writer.finishWriting { semaphore.signal() }
    semaphore.wait()
    if writer.status != .completed {
      throw writer.error ?? EngineError.write
    }
  }

  // MARK: - Video source

  private func exportFromVideo(
    sourceURL: URL, audioPath: String?, width: Int, height: Int, duration: Int, fill: Bool,
    outputURL: URL
  ) throws {
    emit(stage: "generatingVideo", percentage: 0.1, message: "Processing video")
    let asset = loadedAsset(sourceURL)
    guard let sourceVideoTrack = asset.tracks(withMediaType: .video).first else {
      throw EngineError.missingSource
    }

    let composition = AVMutableComposition()
    let targetDuration = CMTime(seconds: Double(duration), preferredTimescale: 600)
    let clipDuration = min(targetDuration, asset.duration)

    guard
      let videoTrack = composition.addMutableTrack(
        withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    else { throw EngineError.export }
    try videoTrack.insertTimeRange(
      CMTimeRange(start: .zero, duration: clipDuration), of: sourceVideoTrack, at: .zero)

    let externalAudio = (audioPath != nil) && FileManager.default.fileExists(atPath: audioPath!)
    if externalAudio {
      let audioAsset = loadedAsset(URL(fileURLWithPath: audioPath!))
      if let audioSource = audioAsset.tracks(withMediaType: .audio).first,
        let audioTrack = composition.addMutableTrack(
          withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      {
        let audioDuration = min(clipDuration, audioAsset.duration)
        try? audioTrack.insertTimeRange(
          CMTimeRange(start: .zero, duration: audioDuration), of: audioSource, at: .zero)
      }
    } else if let sourceAudioTrack = asset.tracks(withMediaType: .audio).first,
      let audioTrack = composition.addMutableTrack(
        withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
    {
      try? audioTrack.insertTimeRange(
        CMTimeRange(start: .zero, duration: clipDuration), of: sourceAudioTrack, at: .zero)
    }

    let renderSize = CGSize(width: width, height: height)
    let naturalSize = sourceVideoTrack.naturalSize
    let preferred = sourceVideoTrack.preferredTransform
    let displayed = naturalSize.applying(preferred)
    let displayWidth = abs(displayed.width)
    let displayHeight = abs(displayed.height)
    let scale =
      fill
      ? max(renderSize.width / displayWidth, renderSize.height / displayHeight)
      : min(renderSize.width / displayWidth, renderSize.height / displayHeight)
    let translateX = (renderSize.width - displayWidth * scale) / 2
    let translateY = (renderSize.height - displayHeight * scale) / 2
    var transform = preferred.concatenating(CGAffineTransform(scaleX: scale, y: scale))
    transform = transform.concatenating(
      CGAffineTransform(translationX: translateX, y: translateY))

    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    layerInstruction.setTransform(transform, at: .zero)
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRange(start: .zero, duration: clipDuration)
    instruction.layerInstructions = [layerInstruction]

    let videoComposition = AVMutableVideoComposition()
    videoComposition.renderSize = renderSize
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
    videoComposition.instructions = [instruction]

    guard
      let export = AVAssetExportSession(
        asset: composition, presetName: AVAssetExportPresetHighestQuality)
    else { throw EngineError.export }
    try? FileManager.default.removeItem(at: outputURL)
    export.outputURL = outputURL
    export.outputFileType = .mp4
    export.videoComposition = videoComposition
    export.shouldOptimizeForNetworkUse = true

    emit(stage: "mergingAudio", percentage: 0.7, message: "Rendering")
    try runExportSession(export)
  }

  // MARK: - Audio mux

  private func mux(videoURL: URL, audioURL: URL, duration: Int, to outputURL: URL) throws {
    let composition = AVMutableComposition()
    let videoAsset = loadedAsset(videoURL)
    let audioAsset = loadedAsset(audioURL)
    let targetDuration = CMTime(seconds: Double(duration), preferredTimescale: 600)

    if let videoSource = videoAsset.tracks(withMediaType: .video).first,
      let videoTrack = composition.addMutableTrack(
        withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    {
      try videoTrack.insertTimeRange(
        CMTimeRange(start: .zero, duration: min(targetDuration, videoAsset.duration)),
        of: videoSource, at: .zero)
    }
    if let audioSource = audioAsset.tracks(withMediaType: .audio).first,
      let audioTrack = composition.addMutableTrack(
        withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
    {
      try? audioTrack.insertTimeRange(
        CMTimeRange(start: .zero, duration: min(targetDuration, audioAsset.duration)),
        of: audioSource, at: .zero)
    }

    guard
      let export = AVAssetExportSession(
        asset: composition, presetName: AVAssetExportPresetHighestQuality)
    else { throw EngineError.export }
    try? FileManager.default.removeItem(at: outputURL)
    export.outputURL = outputURL
    export.outputFileType = .mp4
    try runExportSession(export)
  }

  private func runExportSession(_ export: AVAssetExportSession) throws {
    let semaphore = DispatchSemaphore(value: 0)
    export.exportAsynchronously { semaphore.signal() }
    while semaphore.wait(timeout: .now() + 0.2) == .timedOut {
      if isCancelled {
        export.cancelExport()
      }
    }
    switch export.status {
    case .completed:
      return
    case .cancelled:
      throw EngineError.cancelled
    default:
      throw export.error ?? EngineError.export
    }
  }

  // MARK: - Rendering helpers

  private func pixelBuffer(from image: UIImage, width: Int, height: Int, fill: Bool)
    -> CVPixelBuffer?
  {
    let attrs: [String: Any] = [
      kCVPixelBufferCGImageCompatibilityKey as String: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
    ]
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs as CFDictionary,
      &pixelBuffer)
    guard status == kCVReturnSuccess, let buffer = pixelBuffer, let cgImage = image.cgImage else {
      return nil
    }

    CVPixelBufferLockBaseAddress(buffer, [])
    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
    guard
      let context = CGContext(
        data: CVPixelBufferGetBaseAddress(buffer),
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
    else { return nil }

    // Letterbox background matches the web export (#111827).
    context.setFillColor(red: 17 / 255, green: 24 / 255, blue: 39 / 255, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    let imageWidth = CGFloat(cgImage.width)
    let imageHeight = CGFloat(cgImage.height)
    let targetWidth = CGFloat(width)
    let targetHeight = CGFloat(height)
    let scale =
      fill
      ? max(targetWidth / imageWidth, targetHeight / imageHeight)
      : min(targetWidth / imageWidth, targetHeight / imageHeight)
    let drawWidth = imageWidth * scale
    let drawHeight = imageHeight * scale
    let drawRect = CGRect(
      x: (targetWidth - drawWidth) / 2,
      y: (targetHeight - drawHeight) / 2,
      width: drawWidth,
      height: drawHeight)
    context.draw(cgImage, in: drawRect)
    return buffer
  }

  private func normalizedImage(_ image: UIImage) -> UIImage {
    if image.imageOrientation == .up { return image }
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = image.scale
    let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: image.size))
    }
  }

  // MARK: - Files & utilities

  /// Returns an asset whose `tracks` and `duration` are loaded. Reading those
  /// properties straight off a freshly created `AVURLAsset` can return empty or
  /// zero before loading completes, which would silently drop the audio track.
  private func loadedAsset(_ url: URL) -> AVURLAsset {
    let asset = AVURLAsset(
      url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
    let semaphore = DispatchSemaphore(value: 0)
    asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"]) {
      semaphore.signal()
    }
    semaphore.wait()
    return asset
  }

  private func outputDirectory() throws -> URL {
    let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("stillora_exports", isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    return base
  }

  private func makeOutputURL() throws -> URL {
    try outputDirectory().appendingPathComponent("stillora-\(UUID().uuidString).mp4")
  }

  private func makeTempURL() throws -> URL {
    try outputDirectory().appendingPathComponent("tmp-\(UUID().uuidString).mp4")
  }

  private func clearTemporaryFiles() {
    guard let base = try? outputDirectory() else { return }
    let files =
      (try? FileManager.default.contentsOfDirectory(at: base, includingPropertiesForKeys: nil))
      ?? []
    for file in files where file.lastPathComponent.hasPrefix("tmp-") {
      try? FileManager.default.removeItem(at: file)
    }
  }

  private func isVideoFile(_ path: String) -> Bool {
    let ext = (path as NSString).pathExtension.lowercased()
    return ["mp4", "mov", "m4v", "webm", "avi", "mkv", "3gp", "m2ts"].contains(ext)
  }

  private func evenDimension(_ value: Int) -> Int {
    let safe = max(2, value)
    return safe % 2 == 0 ? safe : safe + 1
  }

  private func emit(stage: String, percentage: Double, message: String?) {
    guard let sink = progressSink else { return }
    var payload: [String: Any] = ["stage": stage, "percentage": percentage]
    if let message = message { payload["message"] = message }
    DispatchQueue.main.async { sink(payload) }
  }
}
