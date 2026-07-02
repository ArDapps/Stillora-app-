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
    case "removeSilence":
      guard let args = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_arguments", message: "Export arguments were missing.", details: nil))
        return
      }
      isCancelled = false
      workQueue.async { [weak self] in
        self?.runRemoveSilence(args: args, result: result)
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

  private enum TimelineSource {
    case image(UIImage)
    case video(AVAssetImageGenerator, CMTime)
  }

  private func runExport(args: [String: Any], result: @escaping FlutterResult) {
    let imagePath = args["imagePath"] as? String ?? ""
    let mediaPaths = (args["mediaPaths"] as? [String]) ?? []
    let imagePaths = (args["imagePaths"] as? [String]) ?? []
    let clipDurations = (args["clipDurations"] as? [Int]) ?? []
    let clipVolumes = (args["clipVolumes"] as? [NSNumber])?.map { $0.doubleValue } ?? []
    let audioPath = args["audioPath"] as? String
    let width = evenDimension(args["width"] as? Int ?? 1080)
    let height = evenDimension(args["height"] as? Int ?? 1920)
    let fill = (args["resizeMode"] as? String ?? "fit") == "fill"

    do {
      let outputURL = try makeOutputURL()
      let timelinePaths =
        mediaPaths.isEmpty
        ? (imagePaths.isEmpty ? [imagePath] : imagePaths)
        : mediaPaths

      // Per-clip durations are sent parallel to `mediaPaths`. When they line up
      // with the chosen timeline, the exported length is their sum; otherwise we
      // fall back to the single `durationSeconds` total split evenly.
      let aligned = clipDurations.count == timelinePaths.count
        && clipDurations.allSatisfy { $0 > 0 }
      let totalDuration =
        aligned ? clipDurations.reduce(0, +) : max(1, args["durationSeconds"] as? Int ?? 10)
      let clipSeconds = aligned ? clipDurations : nil

      if timelinePaths.count == 1, let path = timelinePaths.first, isVideoFile(path) {
        // Volume of this clip's own soundtrack (0 = muted). Parallel to the
        // timeline; defaults to full loudness when not supplied.
        let volume = clipVolumes.first ?? 1.0
        try exportFromVideo(
          sourceURL: URL(fileURLWithPath: path), audioPath: audioPath, volume: volume,
          width: width, height: height, duration: totalDuration, fill: fill, outputURL: outputURL)
      } else if timelinePaths.contains(where: { isVideoFile($0) }) {
        try exportFromTimeline(
          mediaPaths: timelinePaths, clipSeconds: clipSeconds, audioPath: audioPath, width: width,
          height: height, duration: totalDuration, fill: fill, outputURL: outputURL)
      } else {
        try exportFromImage(
          imagePaths: timelinePaths, clipSeconds: clipSeconds, audioPath: audioPath, width: width,
          height: height, duration: totalDuration, fill: fill, outputURL: outputURL)
      }

      emit(stage: "done", percentage: 1.0, message: "Saved")
      result([
        "outputPath": outputURL.path,
        "width": width,
        "height": height,
        "durationSeconds": totalDuration,
      ])
    } catch EngineError.cancelled {
      result(
        FlutterError(code: "cancelled", message: "Export was cancelled.", details: nil))
    } catch EngineError.missingSource {
      result(
        FlutterError(
          code: "missing_source",
          message: "Stillora could not read the selected media. Please choose the file again.",
          details: nil))
    } catch EngineError.render {
      result(
        FlutterError(
          code: "render_failed",
          message: "Stillora could not render one of the selected media files.",
          details: nil))
    } catch EngineError.write {
      result(
        FlutterError(
          code: "write_failed",
          message: "Stillora could not write the exported video.",
          details: nil))
    } catch EngineError.export {
      result(
        FlutterError(
          code: "export_failed",
          message: "Stillora could not finish the video export.",
          details: nil))
    } catch {
      result(
        FlutterError(
          code: "export_failed", message: error.localizedDescription, details: nil))
    }
  }

  // MARK: - Mixed timeline source

  private func exportFromTimeline(
    mediaPaths: [String], clipSeconds: [Int]?, audioPath: String?, width: Int, height: Int,
    duration: Int, fill: Bool, outputURL: URL
  ) throws {
    emit(stage: "preparingImage", percentage: 0.05, message: "Preparing media")
    // Build sources and their per-clip second counts together so that skipping
    // an unreadable item also drops its slice of the timeline.
    var sources: [TimelineSource] = []
    var seconds: [Int] = []
    let aligned = (clipSeconds != nil) && clipSeconds!.count == mediaPaths.count
    for (index, path) in mediaPaths.enumerated() {
      let clip = aligned ? max(1, clipSeconds![index]) : 0
      if isVideoFile(path) {
        let asset = loadedAsset(URL(fileURLWithPath: path))
        guard asset.tracks(withMediaType: .video).first != nil else { continue }
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        sources.append(.video(generator, asset.duration))
        seconds.append(clip)
      } else if let rawImage = UIImage(contentsOfFile: path) {
        sources.append(.image(normalizedImage(rawImage)))
        seconds.append(clip)
      }
    }
    guard !sources.isEmpty else { throw EngineError.missingSource }

    let fps = 30
    let clipFrames =
      aligned ? seconds.map { max(1, $0 * fps) }
      : evenFrames(count: sources.count, totalSeconds: duration, fps: fps)
    let totalSeconds = aligned ? max(1, seconds.reduce(0, +)) : duration

    let needsAudio = (audioPath != nil) && FileManager.default.fileExists(atPath: audioPath!)
    let videoURL = needsAudio ? try makeTempURL() : outputURL

    try writeTimeline(
      sources: sources, clipFrames: clipFrames, width: width, height: height, fill: fill,
      to: videoURL)

    if needsAudio {
      emit(stage: "mergingAudio", percentage: 0.85, message: "Merging audio")
      try mux(
        videoURL: videoURL, audioURL: URL(fileURLWithPath: audioPath!), duration: totalSeconds,
        to: outputURL)
      try? FileManager.default.removeItem(at: videoURL)
    }
    emit(stage: "savingVideo", percentage: 0.95, message: "Saving")
  }

  /// Splits `totalSeconds` of frames across `count` clips as evenly as possible.
  private func evenFrames(count: Int, totalSeconds: Int, fps: Int) -> [Int] {
    guard count > 0 else { return [] }
    let totalFrames = max(count, totalSeconds * fps)
    let base = totalFrames / count
    let remainder = totalFrames - base * count
    return (0..<count).map { base + ($0 < remainder ? 1 : 0) }
  }

  private func writeTimeline(
    sources: [TimelineSource], clipFrames: [Int], width: Int, height: Int, fill: Bool, to url: URL
  ) throws {
    try? FileManager.default.removeItem(at: url)
    let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
    // HEVC/H.265 when the device can encode it (~40-50% smaller than H.264 at
    // the same quality); falls back to H.264 on older hardware. Controlled
    // bitrate + a 2s keyframe interval keep files small, especially for static
    // slideshows.
    let useHEVC = AVAssetExportSession.allExportPresets()
      .contains(AVAssetExportPresetHEVCHighestQuality)
    let settings: [String: Any] = [
      AVVideoCodecKey: useHEVC ? AVVideoCodecType.hevc : AVVideoCodecType.h264,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height,
      AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey:
          Int(Double(width * height) * 30.0 * (useHEVC ? 0.06 : 0.10)),
        AVVideoMaxKeyFrameIntervalKey: 60,
      ],
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
    let totalFrames = max(1, clipFrames.reduce(0, +))
    var frame = 0
    var sourceIndex = 0
    var segmentStart = 0

    while frame < totalFrames {
      if isCancelled {
        input.markAsFinished()
        writer.cancelWriting()
        throw EngineError.cancelled
      }
      if input.isReadyForMoreMediaData {
        // Advance to the clip that owns this frame (frames climb monotonically).
        while sourceIndex < clipFrames.count - 1
          && frame >= segmentStart + clipFrames[sourceIndex]
        {
          segmentStart += clipFrames[sourceIndex]
          sourceIndex += 1
        }
        let segmentFrames = max(1, clipFrames[sourceIndex])
        let localFrame = frame - segmentStart
        guard
          let buffer = try timelinePixelBuffer(
            source: sources[sourceIndex], localFrame: localFrame, segmentFrames: segmentFrames,
            width: width, height: height, fill: fill)
        else { throw EngineError.render }

        let time = CMTime(value: CMTimeValue(frame), timescale: fps)
        if !adaptor.append(buffer, withPresentationTime: time) {
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

  private func timelinePixelBuffer(
    source: TimelineSource, localFrame: Int, segmentFrames: Int, width: Int, height: Int, fill: Bool
  ) throws -> CVPixelBuffer? {
    switch source {
    case .image(let image):
      return pixelBuffer(from: image, width: width, height: height, fill: fill)
    case .video(let generator, let sourceDuration):
      let sourceDurationSeconds = max(0.001, CMTimeGetSeconds(sourceDuration))
      let progress =
        segmentFrames <= 1 ? 0 : Double(localFrame) / Double(max(1, segmentFrames - 1))
      let seconds = min(sourceDurationSeconds - 0.001, sourceDurationSeconds * progress)
      let time = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
      let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
      return pixelBuffer(
        from: UIImage(cgImage: cgImage), width: width, height: height, fill: fill)
    }
  }

  // MARK: - Image source

  private func exportFromImage(
    imagePaths: [String], clipSeconds: [Int]?, audioPath: String?, width: Int, height: Int,
    duration: Int, fill: Bool, outputURL: URL
  ) throws {
    emit(stage: "preparingImage", percentage: 0.05, message: "Preparing image")

    // Render every selected image into a pixel buffer. Unreadable images are
    // skipped so one bad file does not abort the whole slideshow — and their
    // per-clip seconds are dropped alongside them to stay in sync.
    var buffers: [CVPixelBuffer] = []
    var seconds: [Int] = []
    let aligned = (clipSeconds != nil) && clipSeconds!.count == imagePaths.count
    for (index, path) in imagePaths.enumerated() {
      guard let rawImage = UIImage(contentsOfFile: path) else { continue }
      let image = normalizedImage(rawImage)
      guard let buffer = pixelBuffer(from: image, width: width, height: height, fill: fill)
      else { continue }
      buffers.append(buffer)
      seconds.append(aligned ? max(1, clipSeconds![index]) : 0)
    }
    guard !buffers.isEmpty else { throw EngineError.missingSource }

    let fps = 30
    let clipFrames =
      aligned ? seconds.map { max(1, $0 * fps) }
      : evenFrames(count: buffers.count, totalSeconds: duration, fps: fps)
    let totalSeconds = aligned ? max(1, seconds.reduce(0, +)) : duration

    // When there is audio we render to a silent intermediate, then mux.
    let needsAudio = (audioPath != nil) && FileManager.default.fileExists(atPath: audioPath!)
    let videoURL = needsAudio ? try makeTempURL() : outputURL

    try writeSlideshow(
      buffers: buffers, clipFrames: clipFrames, width: width, height: height, to: videoURL)

    if needsAudio {
      emit(stage: "mergingAudio", percentage: 0.85, message: "Merging audio")
      try mux(
        videoURL: videoURL, audioURL: URL(fileURLWithPath: audioPath!), duration: totalSeconds,
        to: outputURL)
      try? FileManager.default.removeItem(at: videoURL)
    }
    emit(stage: "savingVideo", percentage: 0.95, message: "Saving")
  }

  /// Writes a still video that cycles through `buffers`, giving each image the
  /// frame budget in `clipFrames`. A single buffer produces a static clip.
  private func writeSlideshow(
    buffers: [CVPixelBuffer], clipFrames: [Int], width: Int, height: Int, to url: URL
  ) throws {
    try? FileManager.default.removeItem(at: url)
    let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
    // HEVC/H.265 when the device can encode it (~40-50% smaller than H.264 at
    // the same quality); falls back to H.264 on older hardware. Controlled
    // bitrate + a 2s keyframe interval keep files small, especially for static
    // slideshows.
    let useHEVC = AVAssetExportSession.allExportPresets()
      .contains(AVAssetExportPresetHEVCHighestQuality)
    let settings: [String: Any] = [
      AVVideoCodecKey: useHEVC ? AVVideoCodecType.hevc : AVVideoCodecType.h264,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height,
      AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey:
          Int(Double(width * height) * 30.0 * (useHEVC ? 0.06 : 0.10)),
        AVVideoMaxKeyFrameIntervalKey: 60,
      ],
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
    let totalFrames = max(1, clipFrames.reduce(0, +))
    var frame = 0
    var bufferIndex = 0
    var segmentStart = 0

    while frame < totalFrames {
      if isCancelled {
        input.markAsFinished()
        writer.cancelWriting()
        throw EngineError.cancelled
      }
      if input.isReadyForMoreMediaData {
        while bufferIndex < clipFrames.count - 1
          && frame >= segmentStart + clipFrames[bufferIndex]
        {
          segmentStart += clipFrames[bufferIndex]
          bufferIndex += 1
        }
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
    sourceURL: URL, audioPath: String?, volume: Double, width: Int, height: Int, duration: Int,
    fill: Bool, outputURL: URL
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

    // When the user mutes the clip we simply leave the source audio out. A
    // partial volume keeps the track but scales it down via an audio mix.
    let muted = volume <= 0
    var audioMix: AVAudioMix?
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
    } else if !muted, let sourceAudioTrack = asset.tracks(withMediaType: .audio).first,
      let audioTrack = composition.addMutableTrack(
        withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
    {
      try? audioTrack.insertTimeRange(
        CMTimeRange(start: .zero, duration: clipDuration), of: sourceAudioTrack, at: .zero)
      if volume < 1.0 {
        let params = AVMutableAudioMixInputParameters(track: audioTrack)
        params.setVolume(Float(volume), at: .zero)
        let mix = AVMutableAudioMix()
        mix.inputParameters = [params]
        audioMix = mix
      }
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
    export.audioMix = audioMix
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

  // MARK: - Remove silence / speed (ported from the macOS engine)

  /// Cuts silent gaps, optionally speeds up (time-scaled, pitch preserved), and
  /// optionally loops under a new soundtrack. The Speed section calls this with a
  /// huge `minSilenceMs` so nothing is cut — only speed/mute/loop are applied.
  private func runRemoveSilence(args: [String: Any], result: @escaping FlutterResult) {
    let videoPath = args["videoPath"] as? String ?? ""
    let width = evenDimension(args["width"] as? Int ?? 1080)
    let height = evenDimension(args["height"] as? Int ?? 1920)
    let thresholdDb = args["thresholdDb"] as? Double ?? -35
    let minSilenceSec = Double(args["minSilenceMs"] as? Int ?? 400) / 1000.0
    let paddingSec = Double(args["paddingMs"] as? Int ?? 100) / 1000.0
    let speed = max(1, args["speed"] as? Int ?? 1)
    let muteAudio = args["muteAudio"] as? Bool ?? false
    let newAudioPath = args["newAudioPath"] as? String
    let hasNewAudio =
      newAudioPath != nil && FileManager.default.fileExists(atPath: newAudioPath!)
    let keepOriginalAudio = !(muteAudio || hasNewAudio)

    do {
      let outputURL = try makeOutputURL()
      let cutURL = hasNewAudio ? try makeOutputURL() : outputURL
      let asset = loadedAsset(URL(fileURLWithPath: videoPath))
      guard let videoSrc = asset.tracks(withMediaType: .video).first else {
        throw EngineError.missingSource
      }
      let totalDuration = CMTimeGetSeconds(asset.duration)

      emit(stage: "preparingImage", percentage: 0.1, message: "Analyzing audio")
      var ranges = keptRanges(
        asset: asset, thresholdDb: thresholdDb, minSilenceSec: minSilenceSec,
        paddingSec: paddingSec, totalDuration: totalDuration)
      if ranges.isEmpty { ranges = [(0, totalDuration)] }

      emit(stage: "generatingVideo", percentage: 0.4, message: "Processing")
      let composition = AVMutableComposition()
      guard
        let vTrack = composition.addMutableTrack(
          withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
      else { throw EngineError.export }
      let aSrc = keepOriginalAudio ? asset.tracks(withMediaType: .audio).first : nil
      let aTrack = aSrc != nil
        ? composition.addMutableTrack(
          withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        : nil

      var cursor = CMTime.zero
      for (start, end) in ranges {
        let dur = max(0, end - start)
        if dur <= 0 { continue }
        let range = CMTimeRange(
          start: CMTime(seconds: start, preferredTimescale: 600),
          duration: CMTime(seconds: dur, preferredTimescale: 600))
        try? vTrack.insertTimeRange(range, of: videoSrc, at: cursor)
        if let aSrc = aSrc, let aTrack = aTrack {
          try? aTrack.insertTimeRange(range, of: aSrc, at: cursor)
        }
        cursor = CMTimeAdd(cursor, range.duration)
      }

      var finalDuration = cursor
      if speed > 1 {
        let scaled = CMTimeMultiplyByFloat64(cursor, multiplier: 1.0 / Double(speed))
        let full = CMTimeRange(start: .zero, duration: cursor)
        vTrack.scaleTimeRange(full, toDuration: scaled)
        aTrack?.scaleTimeRange(full, toDuration: scaled)
        finalDuration = scaled
      }
      let keptSeconds = max(1, Int(CMTimeGetSeconds(finalDuration).rounded()))

      let renderSize = CGSize(width: width, height: height)
      let naturalSize = videoSrc.naturalSize
      let preferred = videoSrc.preferredTransform
      let displayed = naturalSize.applying(preferred)
      let dispW = abs(displayed.width)
      let dispH = abs(displayed.height)
      let scale = min(renderSize.width / dispW, renderSize.height / dispH)
      let tx = (renderSize.width - dispW * scale) / 2
      let ty = (renderSize.height - dispH * scale) / 2
      var transform = preferred.concatenating(CGAffineTransform(scaleX: scale, y: scale))
      transform = transform.concatenating(CGAffineTransform(translationX: tx, y: ty))

      let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: vTrack)
      layerInstruction.setTransform(transform, at: .zero)
      let instruction = AVMutableVideoCompositionInstruction()
      instruction.timeRange = CMTimeRange(start: .zero, duration: finalDuration)
      instruction.layerInstructions = [layerInstruction]
      let videoComposition = AVMutableVideoComposition()
      videoComposition.renderSize = renderSize
      videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
      videoComposition.instructions = [instruction]

      guard
        let export = AVAssetExportSession(
          asset: composition, presetName: AVAssetExportPresetHighestQuality)
      else { throw EngineError.export }
      try? FileManager.default.removeItem(at: cutURL)
      export.outputURL = cutURL
      export.outputFileType = .mp4
      export.videoComposition = videoComposition
      export.shouldOptimizeForNetworkUse = true
      export.audioTimePitchAlgorithm = .spectral
      emit(stage: "mergingAudio", percentage: 0.7, message: "Rendering")
      try runExportSession(export)

      var finalSeconds = keptSeconds
      if hasNewAudio, let newAudioPath = newAudioPath {
        emit(stage: "mergingAudio", percentage: 0.9, message: "Adding new audio")
        finalSeconds = try loopVideoUnderAudio(
          videoURL: cutURL, audioPath: newAudioPath, width: width, height: height,
          outputURL: outputURL)
        try? FileManager.default.removeItem(at: cutURL)
      }

      emit(stage: "done", percentage: 1.0, message: "Saved")
      result([
        "outputPath": outputURL.path, "width": width, "height": height,
        "durationSeconds": finalSeconds,
      ])
    } catch EngineError.cancelled {
      result(FlutterError(code: "cancelled", message: "Export was cancelled.", details: nil))
    } catch EngineError.missingSource {
      result(
        FlutterError(
          code: "missing_source", message: "Stillora could not read that video.", details: nil))
    } catch {
      result(
        FlutterError(code: "export_failed", message: error.localizedDescription, details: nil))
    }
  }

  /// Loops [videoURL] to cover [audioPath]'s length and muxes the audio in at
  /// normal speed. Returns the output length in whole seconds.
  private func loopVideoUnderAudio(
    videoURL: URL, audioPath: String, width: Int, height: Int, outputURL: URL
  ) throws -> Int {
    let videoAsset = loadedAsset(videoURL)
    let audioAsset = loadedAsset(URL(fileURLWithPath: audioPath))
    guard let vSrc = videoAsset.tracks(withMediaType: .video).first else {
      throw EngineError.missingSource
    }
    let target =
      audioAsset.duration.seconds > 0 ? audioAsset.duration : videoAsset.duration

    let composition = AVMutableComposition()
    guard
      let vTrack = composition.addMutableTrack(
        withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    else { throw EngineError.export }
    if videoAsset.duration.seconds > 0 {
      var at = CMTime.zero
      while at < target {
        let piece = CMTimeMinimum(CMTimeSubtract(target, at), videoAsset.duration)
        if piece.seconds <= 0 { break }
        try? vTrack.insertTimeRange(
          CMTimeRange(start: .zero, duration: piece), of: vSrc, at: at)
        at = CMTimeAdd(at, piece)
      }
    }
    if let aSrc = audioAsset.tracks(withMediaType: .audio).first,
      let aTrack = composition.addMutableTrack(
        withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
    {
      try? aTrack.insertTimeRange(
        CMTimeRange(start: .zero, duration: CMTimeMinimum(target, audioAsset.duration)),
        of: aSrc, at: .zero)
    }

    guard
      let export = AVAssetExportSession(
        asset: composition, presetName: AVAssetExportPresetHighestQuality)
    else { throw EngineError.export }
    try? FileManager.default.removeItem(at: outputURL)
    export.outputURL = outputURL
    export.outputFileType = .mp4
    export.shouldOptimizeForNetworkUse = true
    try runExportSession(export)
    return max(1, Int(target.seconds.rounded()))
  }

  /// Returns the non-silent (kept) time ranges of an asset's audio, in seconds.
  private func keptRanges(
    asset: AVAsset, thresholdDb: Double, minSilenceSec: Double, paddingSec: Double,
    totalDuration: Double
  ) -> [(Double, Double)] {
    guard let track = asset.tracks(withMediaType: .audio).first,
      let reader = try? AVAssetReader(asset: asset)
    else { return [] }
    let sampleRate = 44100.0
    let settings: [String: Any] = [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsBigEndianKey: false,
      AVNumberOfChannelsKey: 1,
      AVSampleRateKey: sampleRate,
    ]
    let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
    guard reader.canAdd(output) else { return [] }
    reader.add(output)
    reader.startReading()

    let windowSec = 0.03
    let windowSamples = Int(sampleRate * windowSec)
    var windowRms: [Double] = []
    var carry: [Int16] = []

    while reader.status == .reading, let buf = output.copyNextSampleBuffer() {
      guard let block = CMSampleBufferGetDataBuffer(buf) else { continue }
      var length = 0
      var dataPointer: UnsafeMutablePointer<Int8>?
      CMBlockBufferGetDataPointer(
        block, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length,
        dataPointerOut: &dataPointer)
      if let dp = dataPointer {
        dp.withMemoryRebound(to: Int16.self, capacity: length / 2) { p in
          for i in 0..<(length / 2) { carry.append(p[i]) }
        }
      }
      while carry.count >= windowSamples {
        var sum = 0.0
        for i in 0..<windowSamples {
          let v = Double(carry[i]) / 32768.0
          sum += v * v
        }
        windowRms.append((sum / Double(windowSamples)).squareRoot())
        carry.removeFirst(windowSamples)
      }
    }

    let peak = windowRms.max() ?? 0
    guard peak > 0 else { return [] }
    let threshLinear = peak * pow(10.0, thresholdDb / 20.0)
    let windowLoud = windowRms.map { $0 >= threshLinear }

    var ranges: [(Double, Double)] = []
    var i = 0
    while i < windowLoud.count {
      if windowLoud[i] {
        var j = i
        while j < windowLoud.count && windowLoud[j] { j += 1 }
        ranges.append((Double(i) * windowSec, Double(j) * windowSec))
        i = j
      } else {
        i += 1
      }
    }
    var merged: [(Double, Double)] = []
    for r in ranges {
      if var last = merged.last, r.0 - last.1 < minSilenceSec {
        last.1 = r.1
        merged[merged.count - 1] = last
      } else {
        merged.append(r)
      }
    }
    return merged.map { (max(0, $0.0 - paddingSec), min(totalDuration, $0.1 + paddingSec)) }
  }
}
