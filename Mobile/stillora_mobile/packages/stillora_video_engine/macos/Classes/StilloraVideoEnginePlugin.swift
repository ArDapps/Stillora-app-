import AVFoundation
import Cocoa
import CoreGraphics
import CoreImage
import CoreVideo
import FlutterMacOS
import ImageIO
import WebKit

/// macOS implementation of the Stillora video engine, built entirely on
/// AVFoundation / CoreGraphics so it is Mac App Store sandbox compatible (no
/// bundled ffmpeg binary). Mirrors the iOS engine's behaviour but loads images
/// through ImageIO (`CGImage`) instead of `UIImage`.
public class StilloraVideoEnginePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var progressSink: FlutterEventSink?
  private var isCancelled = false
  private let workQueue = DispatchQueue(label: "app.stillora.video_engine", qos: .userInitiated)
  /// Keeps the offscreen HTML→video web view alive for the duration of a render.
  var htmlCapturer: HtmlFrameCapturer?

  // MARK: - Registration

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "stillora_video_engine",
      binaryMessenger: registrar.messenger)
    let instance = StilloraVideoEnginePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let progressChannel = FlutterEventChannel(
      name: "stillora_video_engine/progress",
      binaryMessenger: registrar.messenger)
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
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
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
    case "exportReel":
      guard let args = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_arguments", message: "Reel arguments were missing.", details: nil))
        return
      }
      isCancelled = false
      workQueue.async { [weak self] in
        self?.runReelExport(args: args, result: result)
      }
    case "exportWatermark":
      guard let args = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_arguments", message: "Watermark arguments were missing.", details: nil))
        return
      }
      isCancelled = false
      workQueue.async { [weak self] in
        self?.runWatermarkExport(args: args, result: result)
      }
    case "removeSilence":
      guard let args = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_arguments", message: "Silence arguments were missing.", details: nil))
        return
      }
      isCancelled = false
      workQueue.async { [weak self] in
        self?.runRemoveSilence(args: args, result: result)
      }
    case "renderHtml":
      guard let args = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_arguments", message: "HTML render arguments were missing.",
            details: nil))
        return
      }
      isCancelled = false
      // WKWebView must be driven on the main thread.
      DispatchQueue.main.async { [weak self] in
        self?.renderHtml(args: args, result: result)
      }
    case "colorGrade":
      guard let args = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_arguments", message: "Colour-grade arguments were missing.",
            details: nil))
        return
      }
      isCancelled = false
      workQueue.async { [weak self] in
        self?.runColorGrade(args: args, result: result)
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
    case image(CGImage)
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
      } else if let cgImage = loadCGImage(path: path) {
        sources.append(.image(cgImage))
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
    case .image(let cgImage):
      return pixelBuffer(from: cgImage, width: width, height: height, fill: fill)
    case .video(let generator, let sourceDuration):
      let sourceDurationSeconds = max(0.001, CMTimeGetSeconds(sourceDuration))
      let progress =
        segmentFrames <= 1 ? 0 : Double(localFrame) / Double(max(1, segmentFrames - 1))
      let seconds = min(sourceDurationSeconds - 0.001, sourceDurationSeconds * progress)
      let time = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
      let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
      return pixelBuffer(from: cgImage, width: width, height: height, fill: fill)
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
      guard let cgImage = loadCGImage(path: path) else { continue }
      guard let buffer = pixelBuffer(from: cgImage, width: width, height: height, fill: fill)
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

  /// Loads an orientation-corrected, full-resolution `CGImage` from disk via
  /// ImageIO. `kCGImageSourceCreateThumbnailWithTransform` applies any EXIF
  /// rotation so portrait photos are not drawn sideways.
  private func loadCGImage(path: String) -> CGImage? {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    var maxPixel = 4096
    if let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
      let pixelWidth = (props[kCGImagePropertyPixelWidth] as? Int) ?? 0
      let pixelHeight = (props[kCGImagePropertyPixelHeight] as? Int) ?? 0
      maxPixel = max(maxPixel, max(pixelWidth, pixelHeight))
    }
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixel,
    ]
    return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
  }

  private func pixelBuffer(from cgImage: CGImage, width: Int, height: Int, fill: Bool)
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
    guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
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

  // MARK: - Reel compositing

  private func runReelExport(args: [String: Any], result: @escaping FlutterResult) {
    let rawLayers = (args["layers"] as? [[String: Any]]) ?? []
    let audioPath = args["audioPath"] as? String
    let width = evenDimension(args["width"] as? Int ?? 1080)
    let height = evenDimension(args["height"] as? Int ?? 1920)
    let duration = max(1, args["durationSeconds"] as? Int ?? 5)
    let effect = args["effect"] as? String ?? "none"
    let transition = args["transition"] as? String ?? "none"
    let mockup = args["mockup"] as? String ?? "none"

    do {
      let outputURL = try makeOutputURL()
      try exportReelComposite(
        rawLayers: rawLayers, audioPath: audioPath, width: width, height: height,
        duration: duration, effect: effect, transition: transition, mockup: mockup,
        outputURL: outputURL)
      emit(stage: "done", percentage: 1.0, message: "Saved")
      result([
        "outputPath": outputURL.path, "width": width, "height": height,
        "durationSeconds": duration,
      ])
    } catch EngineError.cancelled {
      result(FlutterError(code: "cancelled", message: "Export was cancelled.", details: nil))
    } catch EngineError.missingSource {
      result(
        FlutterError(
          code: "missing_source", message: "Stillora could not read the reel media.", details: nil))
    } catch {
      result(
        FlutterError(code: "export_failed", message: error.localizedDescription, details: nil))
    }
  }

  /// Composites a reel (any mix of image + video layers) with a custom Core
  /// Image compositor: exact z-order, position/size, looped videos, glow + fade.
  /// Image-only reels get a black "driver" video track so the composition has a
  /// timeline for the compositor to run on.
  private func exportReelComposite(
    rawLayers: [[String: Any]], audioPath: String?, width: Int, height: Int, duration: Int,
    effect: String, transition: String, mockup: String, outputURL: URL
  ) throws {
    emit(stage: "preparingImage", percentage: 0.05, message: "Preparing media")
    let composition = AVMutableComposition()
    let renderSize = CGSize(width: width, height: height)
    let targetDuration = CMTime(seconds: Double(duration), preferredTimescale: 600)

    var infos: [ReelLayerInfo] = []
    var requiredIDs: [NSValue] = []
    for layer in rawLayers {
      let isImage = (layer["isImage"] as? Bool) ?? true
      guard let path = layer["path"] as? String else { continue }
      let x = CGFloat((layer["x"] as? Double) ?? 0)
      let y = CGFloat((layer["y"] as? Double) ?? 0)
      let scale = CGFloat((layer["scale"] as? Double) ?? 1)
      // Optional voice window (seconds). Absent → the whole reel. 3D object
      // overlays send a real range so they only show while the voice plays.
      let start = max(0, (layer["start"] as? Double) ?? 0)
      var end = (layer["end"] as? Double) ?? Double(duration)
      end = min(end, Double(duration))
      let windowed = (layer["start"] != nil) || (layer["end"] != nil)
      if windowed && end <= start { continue }
      let startT = CMTime(seconds: start, preferredTimescale: 600)
      let endT = CMTime(seconds: end, preferredTimescale: 600)
      if isImage {
        guard let cg = loadCGImage(path: path) else { continue }
        let info = ReelLayerInfo()
        info.isImage = true
        info.ciImage = CIImage(cgImage: cg)
        info.x = x; info.y = y; info.scale = scale
        if windowed { info.start = start; info.end = end }
        infos.append(info)
      } else {
        let asset = loadedAsset(URL(fileURLWithPath: path))
        guard let src = asset.tracks(withMediaType: .video).first,
          let track = composition.addMutableTrack(
            withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        else { continue }
        // Lay frames only inside the window (looping to fill it); full-reel
        // layers span the whole timeline.
        let fillStart = windowed ? startT : CMTime.zero
        let fillEnd = windowed ? endT : targetDuration
        if asset.duration.seconds > 0 {
          var at = fillStart
          while at < fillEnd {
            let piece = CMTimeMinimum(CMTimeSubtract(fillEnd, at), asset.duration)
            if piece.seconds <= 0 { break }
            try? track.insertTimeRange(
              CMTimeRange(start: .zero, duration: piece), of: src, at: at)
            at = CMTimeAdd(at, piece)
          }
        }
        requiredIDs.append(NSNumber(value: Int(track.trackID)))
        let info = ReelLayerInfo()
        info.isImage = false
        info.trackID = track.trackID
        info.preferredTransform = src.preferredTransform
        info.x = x; info.y = y; info.scale = scale
        if windowed { info.start = start; info.end = end }
        infos.append(info)
      }
    }
    guard !infos.isEmpty else { throw EngineError.missingSource }

    // Image-only reels have no video track to drive the composition timeline, so
    // add a black "driver" track. The compositor ignores it (not a layer) but it
    // gives AVFoundation a video timeline to render frames over.
    var driverURL: URL?
    if requiredIDs.isEmpty {
      let driver = try makeBlackDriver(width: width, height: height, duration: duration)
      driverURL = driver
      let driverAsset = loadedAsset(driver)
      if let dsrc = driverAsset.tracks(withMediaType: .video).first,
        let dtrack = composition.addMutableTrack(
          withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
      {
        try? dtrack.insertTimeRange(
          CMTimeRange(start: .zero, duration: CMTimeMinimum(targetDuration, driverAsset.duration)),
          of: dsrc, at: .zero)
      }
    }
    defer { if let driverURL = driverURL { try? FileManager.default.removeItem(at: driverURL) } }

    if let audioPath = audioPath, FileManager.default.fileExists(atPath: audioPath) {
      let audioAsset = loadedAsset(URL(fileURLWithPath: audioPath))
      if let asrc = audioAsset.tracks(withMediaType: .audio).first,
        let atrack = composition.addMutableTrack(
          withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      {
        if audioAsset.duration.seconds > 0 {
          var at = CMTime.zero
          while at < targetDuration {
            let piece = CMTimeMinimum(CMTimeSubtract(targetDuration, at), audioAsset.duration)
            try? atrack.insertTimeRange(
              CMTimeRange(start: .zero, duration: piece), of: asrc, at: at)
            at = CMTimeAdd(at, piece)
            if piece.seconds <= 0 { break }
          }
        }
      }
    }

    let instruction = ReelInstruction()
    instruction.timeRange = CMTimeRange(start: .zero, duration: targetDuration)
    instruction.requiredSourceTrackIDs = requiredIDs.isEmpty ? nil : requiredIDs
    instruction.layers = infos
    instruction.renderSize = renderSize
    instruction.totalSeconds = Double(duration)
    instruction.effect = effect
    instruction.transition = transition
    instruction.mockup = mockup

    let videoComposition = AVMutableVideoComposition()
    videoComposition.customVideoCompositorClass = ReelCompositor.self
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
    emit(stage: "generatingVideo", percentage: 0.3, message: "Compositing layers")
    try runExportSession(export)
  }

  // MARK: - Watermark compositing

  private func runWatermarkExport(args: [String: Any], result: @escaping FlutterResult) {
    guard let videoPath = args["videoPath"] as? String else {
      result(
        FlutterError(
          code: "invalid_arguments", message: "No base video was provided.", details: nil))
      return
    }
    let overlays = (args["overlays"] as? [[String: Any]]) ?? []
    let width = evenDimension(args["width"] as? Int ?? 1080)
    let height = evenDimension(args["height"] as? Int ?? 1920)
    let duration = max(1, args["durationSeconds"] as? Int ?? 5)
    let color = ColorGradeParams(map: (args["color"] as? [String: Any]) ?? [:])

    do {
      let outputURL = try makeOutputURL()
      let outSize = try exportWatermarkComposite(
        videoPath: videoPath, overlays: overlays, width: width, height: height,
        duration: duration, color: color, outputURL: outputURL)
      emit(stage: "done", percentage: 1.0, message: "Saved")
      result([
        "outputPath": outputURL.path, "width": outSize.width, "height": outSize.height,
        "durationSeconds": duration,
      ])
    } catch EngineError.cancelled {
      result(FlutterError(code: "cancelled", message: "Export was cancelled.", details: nil))
    } catch EngineError.missingSource {
      result(
        FlutterError(
          code: "missing_source", message: "Stillora could not read the video.", details: nil))
    } catch {
      result(
        FlutterError(code: "export_failed", message: error.localizedDescription, details: nil))
    }
  }

  /// Bakes a colour grade onto a finished video as a single CoreImage pass,
  /// preserving its audio. The per-channel gains (CIColorMatrix) fold exposure +
  /// warmth + tint; CIColorControls applies brightness/contrast/saturation;
  /// CISharpenLuminance sharpens. This mirrors the ffmpeg desktop pass and the
  /// Flutter live preview so the export matches what the user previews.
  private func runColorGrade(args: [String: Any], result: @escaping FlutterResult) {
    guard let videoPath = args["videoPath"] as? String else {
      result(
        FlutterError(
          code: "invalid_arguments", message: "No video was provided.", details: nil))
      return
    }
    let adjust = (args["adjust"] as? [String: Any]) ?? [:]
    let rGain = CGFloat((adjust["rGain"] as? Double) ?? 1)
    let gGain = CGFloat((adjust["gGain"] as? Double) ?? 1)
    let bGain = CGFloat((adjust["bGain"] as? Double) ?? 1)
    let brightness = CGFloat((adjust["brightness"] as? Double) ?? 0)
    let contrast = CGFloat((adjust["contrast"] as? Double) ?? 1)
    let saturation = CGFloat((adjust["saturation"] as? Double) ?? 1)
    let sharpness = CGFloat((adjust["sharpness"] as? Double) ?? 0)
    let width = args["width"] as? Int ?? 0
    let height = args["height"] as? Int ?? 0
    let duration = max(1, args["durationSeconds"] as? Int ?? 1)

    do {
      emit(stage: "generatingVideo", percentage: 0.2, message: "Applying colour grade")
      let asset = loadedAsset(URL(fileURLWithPath: videoPath))

      let videoComposition = AVVideoComposition(asset: asset) { request in
        var image = request.sourceImage.clampedToExtent()

        if let matrix = CIFilter(name: "CIColorMatrix") {
          matrix.setValue(image, forKey: kCIInputImageKey)
          matrix.setValue(CIVector(x: rGain, y: 0, z: 0, w: 0), forKey: "inputRVector")
          matrix.setValue(CIVector(x: 0, y: gGain, z: 0, w: 0), forKey: "inputGVector")
          matrix.setValue(CIVector(x: 0, y: 0, z: bGain, w: 0), forKey: "inputBVector")
          image = matrix.outputImage ?? image
        }
        if let controls = CIFilter(name: "CIColorControls") {
          controls.setValue(image, forKey: kCIInputImageKey)
          controls.setValue(brightness, forKey: kCIInputBrightnessKey)
          controls.setValue(contrast, forKey: kCIInputContrastKey)
          controls.setValue(saturation, forKey: kCIInputSaturationKey)
          image = controls.outputImage ?? image
        }
        if sharpness > 0, let sharpen = CIFilter(name: "CISharpenLuminance") {
          sharpen.setValue(image, forKey: kCIInputImageKey)
          sharpen.setValue(sharpness * 1.5, forKey: kCIInputSharpnessKey)
          image = sharpen.outputImage ?? image
        }

        image = image.cropped(to: request.sourceImage.extent)
        request.finish(with: image, context: nil)
      }

      guard
        let export = AVAssetExportSession(
          asset: asset, presetName: AVAssetExportPresetHighestQuality)
      else { throw EngineError.export }
      let outputURL = try makeOutputURL()
      try? FileManager.default.removeItem(at: outputURL)
      export.outputURL = outputURL
      export.outputFileType = .mp4
      export.videoComposition = videoComposition
      export.shouldOptimizeForNetworkUse = true

      emit(stage: "savingVideo", percentage: 0.7, message: "Rendering")
      try runExportSession(export)
      emit(stage: "done", percentage: 1.0, message: "Saved")
      result([
        "outputPath": outputURL.path,
        "width": width, "height": height, "durationSeconds": duration,
      ])
    } catch EngineError.cancelled {
      result(FlutterError(code: "cancelled", message: "Export was cancelled.", details: nil))
    } catch {
      result(
        FlutterError(code: "export_failed", message: error.localizedDescription, details: nil))
    }
  }

  /// Burns watermark overlays onto a base video, each shown only within its time
  /// window, keeping the base video's own audio. Reuses the reel Core Image
  /// compositor (which now honours each layer's start/end) with the base video
  /// as the full-frame back layer.
  private func exportWatermarkComposite(
    videoPath: String, overlays: [[String: Any]], width: Int, height: Int, duration: Int,
    color: ColorGradeParams, outputURL: URL
  ) throws -> (width: Int, height: Int) {
    emit(stage: "preparingImage", percentage: 0.05, message: "Preparing media")
    let composition = AVMutableComposition()
    let targetDuration = CMTime(seconds: Double(duration), preferredTimescale: 600)

    var infos: [ReelLayerInfo] = []
    var requiredIDs: [NSValue] = []

    // Base video: the full-frame back layer.
    let baseAsset = loadedAsset(URL(fileURLWithPath: videoPath))
    guard let baseSrc = baseAsset.tracks(withMediaType: .video).first,
      let baseTrack = composition.addMutableTrack(
        withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    else { throw EngineError.missingSource }

    // Derive the render size from the base video's TRUE display aspect (rather
    // than the Flutter-reported width/height, which can be swapped for rotated
    // phone videos and cropped the base). The requested resolution tier is the
    // short edge = min(width, height): Original passes the source size, while
    // 720p/1080p/2K/4K pass that short edge. We scale the true aspect to it, so
    // the output keeps the original aspect (no crop) at the chosen resolution.
    let baseDisplay = baseSrc.naturalSize.applying(baseSrc.preferredTransform)
    let baseW = abs(baseDisplay.width)
    let baseH = abs(baseDisplay.height)
    let targetShort = min(width, height)
    let renderSize: CGSize
    if baseW >= 2, baseH >= 2 {
      let baseShort = min(baseW, baseH)
      let scale = targetShort >= 2 ? CGFloat(targetShort) / baseShort : 1
      renderSize = CGSize(
        width: CGFloat(evenDimension(Int((baseW * scale).rounded()))),
        height: CGFloat(evenDimension(Int((baseH * scale).rounded()))))
    } else {
      renderSize = CGSize(width: width, height: height)
    }
    let baseDur = CMTimeMinimum(targetDuration, baseAsset.duration)
    try? baseTrack.insertTimeRange(
      CMTimeRange(start: .zero, duration: baseDur), of: baseSrc, at: .zero)
    requiredIDs.append(NSNumber(value: Int(baseTrack.trackID)))
    let baseInfo = ReelLayerInfo()
    baseInfo.isImage = false
    baseInfo.trackID = baseTrack.trackID
    baseInfo.preferredTransform = baseSrc.preferredTransform
    baseInfo.x = 0
    baseInfo.y = 0
    baseInfo.scale = 1
    infos.append(baseInfo)

    // Overlays on top, each gated to its time window.
    for overlay in overlays {
      let isImage = (overlay["isImage"] as? Bool) ?? true
      guard let path = overlay["path"] as? String else { continue }
      let x = CGFloat((overlay["x"] as? Double) ?? 0)
      let y = CGFloat((overlay["y"] as? Double) ?? 0)
      let scale = CGFloat((overlay["scale"] as? Double) ?? 0.3)
      let start = max(0, (overlay["start"] as? Double) ?? 0)
      var end = (overlay["end"] as? Double) ?? Double(duration)
      end = min(end, Double(duration))
      if end <= start { continue }
      let startT = CMTime(seconds: start, preferredTimescale: 600)
      let endT = CMTime(seconds: end, preferredTimescale: 600)

      if isImage {
        guard let cg = loadCGImage(path: path) else { continue }
        let info = ReelLayerInfo()
        info.isImage = true
        info.ciImage = CIImage(cgImage: cg)
        info.x = x
        info.y = y
        info.scale = scale
        info.start = start
        info.end = end
        infos.append(info)
      } else {
        let asset = loadedAsset(URL(fileURLWithPath: path))
        guard let src = asset.tracks(withMediaType: .video).first,
          let track = composition.addMutableTrack(
            withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        else { continue }
        // Place the overlay frames only inside its window, looping to fill it.
        if asset.duration.seconds > 0 {
          var at = startT
          while at < endT {
            let piece = CMTimeMinimum(CMTimeSubtract(endT, at), asset.duration)
            if piece.seconds <= 0 { break }
            try? track.insertTimeRange(
              CMTimeRange(start: .zero, duration: piece), of: src, at: at)
            at = CMTimeAdd(at, piece)
          }
        }
        requiredIDs.append(NSNumber(value: Int(track.trackID)))
        let info = ReelLayerInfo()
        info.isImage = false
        info.trackID = track.trackID
        info.preferredTransform = src.preferredTransform
        info.x = x
        info.y = y
        info.scale = scale
        info.start = start
        info.end = end
        infos.append(info)
      }
    }

    // Preserve the base video's own audio.
    if let asrc = baseAsset.tracks(withMediaType: .audio).first,
      let atrack = composition.addMutableTrack(
        withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
    {
      try? atrack.insertTimeRange(
        CMTimeRange(start: .zero, duration: baseDur), of: asrc, at: .zero)
    }

    let instruction = ReelInstruction()
    instruction.timeRange = CMTimeRange(start: .zero, duration: targetDuration)
    instruction.requiredSourceTrackIDs = requiredIDs.isEmpty ? nil : requiredIDs
    instruction.layers = infos
    instruction.renderSize = renderSize
    instruction.totalSeconds = Double(duration)
    instruction.effect = "none"
    instruction.transition = "none"
    instruction.color = color

    let videoComposition = AVMutableVideoComposition()
    videoComposition.customVideoCompositorClass = ReelCompositor.self
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
    emit(stage: "generatingVideo", percentage: 0.3, message: "Compositing watermark")
    try runExportSession(export)
    return (Int(renderSize.width), Int(renderSize.height))
  }

  /// Writes a short black video used only to give image-only reels a timeline.
  private func makeBlackDriver(width: Int, height: Int, duration: Int) throws -> URL {
    let attrs: [String: Any] = [
      kCVPixelBufferCGImageCompatibilityKey as String: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
    ]
    var pb: CVPixelBuffer?
    CVPixelBufferCreate(
      kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs as CFDictionary, &pb)
    guard let buffer = pb else { throw EngineError.write }
    CVPixelBufferLockBaseAddress(buffer, [])
    if let ctx = CGContext(
      data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height, bitsPerComponent: 8,
      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
    {
      ctx.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
      ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
    CVPixelBufferUnlockBaseAddress(buffer, [])
    let url = try makeTempURL()
    try writeSlideshow(
      buffers: [buffer], clipFrames: [max(1, duration * 30)], width: width, height: height, to: url)
    return url
  }

  // MARK: - Remove silence

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
    // The cut clip is silent when muting or swapping in a new soundtrack.
    let keepOriginalAudio = !(muteAudio || hasNewAudio)

    do {
      let outputURL = try makeOutputURL()
      // With a replacement track we render the cut clip to a temp first, then
      // loop it under the new audio.
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
      // No speech detected (or no audio) → keep the whole clip rather than empty.
      if ranges.isEmpty { ranges = [(0, totalDuration)] }

      emit(stage: "generatingVideo", percentage: 0.4, message: "Cutting silence")
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

      // Speed up by time-scaling the kept tracks (audio pitch is preserved via
      // the export session's time-pitch algorithm below).
      var finalDuration = cursor
      if speed > 1 {
        let scaled = CMTimeMultiplyByFloat64(cursor, multiplier: 1.0 / Double(speed))
        let full = CMTimeRange(start: .zero, duration: cursor)
        vTrack.scaleTimeRange(full, toDuration: scaled)
        aTrack?.scaleTimeRange(full, toDuration: scaled)
        finalDuration = scaled
      }
      let keptSeconds = max(1, Int(CMTimeGetSeconds(finalDuration).rounded()))

      // Scale the kept track to the requested resolution (preserve aspect).
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
      export.audioTimePitchAlgorithm = .spectral  // keep voice pitch when sped up
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
  /// normal speed. The video is already at the target render size, so this is a
  /// passthrough composite. Returns the output length in whole seconds.
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
  /// Windows the audio at ~30ms, marks windows below [thresholdDb] as silent,
  /// merges gaps shorter than [minSilenceSec], and pads each kept range.
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

    // Adaptive threshold: silence is relative to the loudest part, so real
    // recordings (which have room tone, never true digital silence) still get
    // cut. [thresholdDb] is the drop below peak that still counts as silence
    // (e.g. -25 → anything 25 dB quieter than the loudest moment is silence).
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

// MARK: - Reel custom compositor

/// One layer to draw in the reel compositor: either a still [ciImage] or a video
/// source identified by [trackID]. Position [x]/[y] is the normalised top-left
/// and [scale] is the width as a fraction of the render width.
final class ReelLayerInfo {
  var isImage = true
  var trackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
  var ciImage: CIImage?
  var preferredTransform: CGAffineTransform = .identity
  var x: CGFloat = 0
  var y: CGFloat = 0
  var scale: CGFloat = 1
  // Seconds during which the layer is drawn. Defaults span the whole clip so
  // reel layers (which never set a window) always show; watermark overlays set
  // a real range.
  var start: Double = 0
  var end: Double = .greatestFiniteMagnitude
}

/// Carries the layer list + render config to the compositor for the whole reel.
final class ReelInstruction: NSObject, AVVideoCompositionInstructionProtocol {
  var timeRange: CMTimeRange = CMTimeRange()
  var enablePostProcessing = false
  var containsTweening = true
  var requiredSourceTrackIDs: [NSValue]?
  var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid

  var layers: [ReelLayerInfo] = []
  var renderSize: CGSize = .zero
  var totalSeconds: Double = 1
  var effect = "none"
  var transition = "none"
  var mockup = "none"
  // Colour grade baked into the composite (identity = no change). Applied to the
  // whole frame in the same pass, so every frame — including the first second —
  // is graded (a separate export pass could passthrough the opening GOP).
  var color: ColorGradeParams = .identity
}

/// Derived colour-grade values (see the Dart `ColorAdjust`): per-channel gains
/// fold exposure + warmth + tint; brightness/contrast/saturation map onto
/// CIColorControls; sharpness onto CISharpenLuminance.
struct ColorGradeParams {
  var rGain: CGFloat = 1
  var gGain: CGFloat = 1
  var bGain: CGFloat = 1
  var brightness: CGFloat = 0
  var contrast: CGFloat = 1
  var saturation: CGFloat = 1
  var sharpness: CGFloat = 0

  static let identity = ColorGradeParams()

  var isIdentity: Bool {
    rGain == 1 && gGain == 1 && bGain == 1 && brightness == 0 && contrast == 1
      && saturation == 1 && sharpness == 0
  }

  init() {}

  init(map: [String: Any]) {
    rGain = CGFloat((map["rGain"] as? Double) ?? 1)
    gGain = CGFloat((map["gGain"] as? Double) ?? 1)
    bGain = CGFloat((map["bGain"] as? Double) ?? 1)
    brightness = CGFloat((map["brightness"] as? Double) ?? 0)
    contrast = CGFloat((map["contrast"] as? Double) ?? 1)
    saturation = CGFloat((map["saturation"] as? Double) ?? 1)
    sharpness = CGFloat((map["sharpness"] as? Double) ?? 0)
  }

  /// Applies the grade to a Core Image frame (same maths as the standalone
  /// `runColorGrade` pass and the ffmpeg/GL passes).
  func apply(to input: CIImage) -> CIImage {
    if isIdentity { return input }
    var image = input
    if let matrix = CIFilter(name: "CIColorMatrix") {
      matrix.setValue(image, forKey: kCIInputImageKey)
      matrix.setValue(CIVector(x: rGain, y: 0, z: 0, w: 0), forKey: "inputRVector")
      matrix.setValue(CIVector(x: 0, y: gGain, z: 0, w: 0), forKey: "inputGVector")
      matrix.setValue(CIVector(x: 0, y: 0, z: bGain, w: 0), forKey: "inputBVector")
      image = matrix.outputImage ?? image
    }
    if let controls = CIFilter(name: "CIColorControls") {
      controls.setValue(image, forKey: kCIInputImageKey)
      controls.setValue(brightness, forKey: kCIInputBrightnessKey)
      controls.setValue(contrast, forKey: kCIInputContrastKey)
      controls.setValue(saturation, forKey: kCIInputSaturationKey)
      image = controls.outputImage ?? image
    }
    if sharpness > 0, let sharpen = CIFilter(name: "CISharpenLuminance") {
      sharpen.setValue(image, forKey: kCIInputImageKey)
      sharpen.setValue(sharpness * 1.5, forKey: kCIInputSharpnessKey)
      image = sharpen.outputImage ?? image
    }
    return image
  }
}

/// Draws every layer over a black canvas at its position/size, per frame, with
/// exact z-order across mixed video + image layers.
final class ReelCompositor: NSObject, AVVideoCompositing {
  private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
  private let colorSpace = CGColorSpaceCreateDeviceRGB()

  var sourcePixelBufferAttributes: [String: Any]? = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
  ]
  var requiredPixelBufferAttributesForRenderContext: [String: Any] = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
  ]

  func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {}

  /// A violet stroked-rect border used for the "glow" effect (bloomed by the
  /// caller). Matches the preview's glowing border. [lineWidth] and [alpha] are
  /// driven by a pulse so the exported glow animates like the preview.
  private func borderImage(size: CGSize, lineWidth: CGFloat, alpha: CGFloat) -> CIImage? {
    let w = Int(size.width)
    let h = Int(size.height)
    guard
      let ctx = CGContext(
        data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return nil }
    ctx.clear(CGRect(x: 0, y: 0, width: w, height: h))
    ctx.setStrokeColor(red: 0.918, green: 0.867, blue: 1.0, alpha: alpha)  // 0xeaddff (preview)
    ctx.setLineWidth(lineWidth)
    let inset = lineWidth / 2 + 2
    ctx.stroke(
      CGRect(
        x: inset, y: inset, width: size.width - 2 * inset, height: size.height - 2 * inset))
    guard let cg = ctx.makeImage() else { return nil }
    return CIImage(cgImage: cg)
  }

  private func imageForLayer(
    _ layer: ReelLayerInfo, request: AVAsynchronousVideoCompositionRequest
  ) -> CIImage? {
    if layer.isImage {
      return layer.ciImage
    }
    guard let buffer = request.sourceFrame(byTrackID: layer.trackID) else { return nil }
    // A video frame comes from a top-down pixel buffer, and AVFoundation's
    // `preferredTransform` is expressed in a top-left-origin space. Applying that
    // matrix directly to a Core Image (y-up) frame flips/rotates rotated phone
    // videos the wrong way (they come out upside down). Map the transform to a
    // CGImagePropertyOrientation instead — Core Image resolves it in its own
    // coordinate space, so the frame is upright and consistent with the cgImage
    // overlays.
    var ci = CIImage(cvPixelBuffer: buffer)
      .oriented(orientationForTransform(layer.preferredTransform))
    ci = ci.transformed(
      by: CGAffineTransform(translationX: -ci.extent.origin.x, y: -ci.extent.origin.y))
    return ci
  }

  /// Maps an AVFoundation track's `preferredTransform` to the equivalent EXIF
  /// orientation for Core Image. Covers the eight standard rotations/mirrors;
  /// anything unexpected falls back to upright.
  private func orientationForTransform(_ t: CGAffineTransform)
    -> CGImagePropertyOrientation
  {
    switch (t.a, t.b, t.c, t.d) {
    case (0, 1, -1, 0): return .right  // 90° clockwise
    case (0, -1, 1, 0): return .left  // 90° counter-clockwise
    case (-1, 0, 0, -1): return .down  // 180°
    case (1, 0, 0, 1): return .up  // no rotation
    case (1, 0, 0, -1): return .upMirrored
    case (-1, 0, 0, 1): return .downMirrored
    case (0, 1, 1, 0): return .leftMirrored
    case (0, -1, -1, 0): return .rightMirrored
    default: return .up
    }
  }

  private func scaleToFill(_ image: CIImage, width: CGFloat, height: CGFloat) -> CIImage {
    let extent = image.extent
    guard extent.width > 0, extent.height > 0 else { return image }
    let scale = max(width / extent.width, height / extent.height)
    let drawW = extent.width * scale
    let drawH = extent.height * scale
    var transform = CGAffineTransform(scaleX: scale, y: scale)
    transform = transform.concatenating(
      CGAffineTransform(
        translationX: (width - drawW) / 2 - extent.origin.x * scale,
        y: (height - drawH) / 2 - extent.origin.y * scale))
    return image.transformed(by: transform).cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
  }

  private func mockupImage(
    from source: CIImage, mockup: String, renderSize: CGSize, seconds: Double
  ) -> CIImage {
    let android = mockup == "androidGraphite"
    let phoneH = renderSize.height * 0.78
    let phoneW = phoneH * (android ? 0.50 : 0.48)
    let side = phoneW * (android ? 0.050 : 0.055)
    let top = phoneH * (android ? 0.038 : 0.046)
    let bottom = phoneH * (android ? 0.040 : 0.044)
    let screenW = phoneW - side * 2
    let screenH = phoneH - top - bottom

    let phoneFrame = CGRect(x: 0, y: 0, width: phoneW, height: phoneH)
    var phone = CIImage(
      color: android
        ? CIColor(red: 0.067, green: 0.094, blue: 0.153, alpha: 1)
        : CIColor(red: 0.095, green: 0.126, blue: 0.200, alpha: 1)
    ).cropped(to: phoneFrame)
    let screen = scaleToFill(source, width: screenW, height: screenH)
      .transformed(by: CGAffineTransform(translationX: side, y: bottom))
    phone = screen.composited(over: phone)

    let notch = android
      ? CGRect(x: phoneW / 2 - phoneW * 0.018, y: phoneH - top * 0.78, width: phoneW * 0.036, height: phoneW * 0.036)
      : CGRect(x: phoneW * 0.34, y: phoneH - top * 0.86, width: phoneW * 0.32, height: top * 0.46)
    phone = CIImage(color: CIColor.black).cropped(to: notch).composited(over: phone)

    let angle = CGFloat((android ? 0.10 : -0.10) + 0.055 * sin(2 * Double.pi * seconds / (android ? 5.6 : 5.1)))
    let lift = CGFloat(sin(2 * Double.pi * seconds / 4.4)) * renderSize.height * 0.018
    let sway = CGFloat(sin(2 * Double.pi * seconds / 6.2)) * renderSize.width * 0.018
    let centerX = renderSize.width / 2 + sway
    let centerY = renderSize.height / 2 + lift

    var transform = CGAffineTransform(translationX: -phoneW / 2, y: -phoneH / 2)
    transform = transform.concatenating(CGAffineTransform(rotationAngle: angle))
    transform = transform.concatenating(CGAffineTransform(translationX: centerX, y: centerY))

    let shadow = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0.48))
      .cropped(to: phoneFrame)
      .transformed(by: transform.concatenating(CGAffineTransform(translationX: 0, y: -renderSize.height * 0.018)))
      .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: renderSize.width * 0.025])
      .cropped(to: CGRect(origin: .zero, size: renderSize))
    return phone.transformed(by: transform).composited(over: shadow)
  }

  func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
    guard let instruction = request.videoCompositionInstruction as? ReelInstruction,
      let output = request.renderContext.newPixelBuffer()
    else {
      request.finish(
        with: NSError(domain: "stillora.reel", code: -1, userInfo: nil))
      return
    }
    let size = instruction.renderSize
    let frame = CGRect(origin: .zero, size: size)
    var acc = CIImage(color: CIColor.black).cropped(to: frame)
    let now = request.compositionTime.seconds

    if instruction.mockup != "none",
      let layer = instruction.layers.first,
      let layerImage = imageForLayer(layer, request: request)
    {
      let bg = CIImage(color: CIColor(red: 0.027, green: 0.027, blue: 0.067, alpha: 1)).cropped(to: frame)
      acc = mockupImage(from: layerImage, mockup: instruction.mockup, renderSize: size, seconds: now)
        .composited(over: bg)
        .cropped(to: frame)
    } else {
      for layer in instruction.layers {
        // Time-gated overlays (watermark): skip layers outside their window.
        if now < layer.start || now >= layer.end { continue }
        guard let layerImage = imageForLayer(layer, request: request) else { continue }
        let extent = layerImage.extent
        guard extent.width > 0, extent.height > 0 else { continue }
        let drawW = layer.scale * size.width
        let s = drawW / extent.width
        let drawH = extent.height * s
        let tx = layer.x * size.width
        let ty = size.height - (layer.y * size.height) - drawH
        var t = CGAffineTransform(scaleX: s, y: s)
        t = t.concatenating(CGAffineTransform(translationX: tx, y: ty))
        acc = layerImage.transformed(by: t).composited(over: acc)
      }
    }

    let black = CIImage(color: CIColor.black).cropped(to: frame)
    let t = request.compositionTime.seconds
    let cx = size.width / 2
    let cy = size.height / 2

    // Per-frame effect, computed from the timestamp to match the preview's
    // animations (EffectAnimator).
    switch instruction.effect {
    case "kenBurns":
      // Ping-pong zoom 1.0..1.14 over 12s, centred.
      let tri = 1 - abs((t / 12).truncatingRemainder(dividingBy: 1.0) * 2 - 1)
      let scale = CGFloat(1 + 0.14 * tri)
      var tr = CGAffineTransform(translationX: cx, y: cy)
      tr = tr.scaledBy(x: scale, y: scale)
      tr = tr.translatedBy(x: -cx, y: -cy)
      acc = acc.transformed(by: tr).composited(over: black).cropped(to: frame)
    case "float":
      let dy = CGFloat(sin(t * 2 * Double.pi / 3) * Double(size.height) * 0.012)
      acc =
        acc.transformed(by: CGAffineTransform(translationX: 0, y: dy))
        .composited(over: black).cropped(to: frame)
    case "shake":
      let dx = CGFloat(sin(t * 2 * Double.pi / 0.6) * Double(size.width) * 0.012)
      let ang = CGFloat(sin(t * 2 * Double.pi / 0.6) * 0.012)
      var tr = CGAffineTransform(translationX: cx + dx, y: cy)
      tr = tr.rotated(by: ang)
      tr = tr.translatedBy(x: -cx, y: -cy)
      acc = acc.transformed(by: tr).composited(over: black).cropped(to: frame)
    case "glow":
      let pulse = (sin(t * Double.pi) + 1) / 2  // 0..1, period 2s
      let lineWidth = max(6, size.width * 0.014) * CGFloat(1 + pulse)
      let alpha = CGFloat(0.5 + 0.5 * pulse)
      let intensity = 1.0 + 1.4 * pulse
      if let border = borderImage(size: size, lineWidth: lineWidth, alpha: alpha) {
        let glowing = border.applyingFilter(
          "CIBloom", parameters: [kCIInputRadiusKey: 16.0, kCIInputIntensityKey: intensity])
        acc = glowing.composited(over: acc).cropped(to: frame)
      }
    default:
      break
    }

    // Per-frame transition overlay, matching the preview's TransitionAnimator.
    switch instruction.transition {
    case "fade":
      let d = instruction.totalSeconds
      var a = 1.0
      if t < 0.5 {
        a = max(0, t / 0.5)
      } else if t > d - 0.5 {
        a = max(0, (d - t) / 0.5)
      }
      if a < 1.0 {
        acc =
          acc.applyingFilter(
            "CIColorMatrix",
            parameters: ["inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(a))]
          ).composited(over: black)
      }
    case "zoom":
      // A brief white flash near the end of every 4s cycle.
      let cycle = (t / 4).truncatingRemainder(dividingBy: 1.0)
      if cycle > 0.8 {
        let phase = (cycle - 0.8) / 0.2
        let a = CGFloat((1 - phase) * 0.4)
        let flash = CIImage(color: CIColor(red: 1, green: 1, blue: 1, alpha: a)).cropped(to: frame)
        acc = flash.composited(over: acc)
      }
    case "swipe":
      // A soft highlight bar sweeping across every 4s.
      let cycle = (t / 4).truncatingRemainder(dividingBy: 1.0)
      let pos = CGFloat(-0.3 + 1.6 * cycle) * size.width
      let barW = size.width * 0.25
      let bar = CIImage(color: CIColor(red: 1, green: 1, blue: 1, alpha: 0.22))
        .cropped(to: CGRect(x: pos, y: 0, width: barW, height: size.height))
      acc = bar.composited(over: acc).cropped(to: frame)
    default:
      break
    }

    // Bake the colour grade into this same frame (no-op when neutral), so every
    // frame is graded without a second export pass.
    acc = instruction.color.apply(to: acc).cropped(to: frame)

    ciContext.render(acc, to: output, bounds: frame, colorSpace: colorSpace)
    request.finish(withComposedVideoFrame: output)
  }
}

// MARK: - HTML → Video (local, on-device)

extension StilloraVideoEnginePlugin {
  /// Renders an animated HTML document (or URL) to an MP4 entirely on-device:
  /// a `WKWebView` paints the page, frames are captured in real time, then
  /// AVFoundation encodes them (and muxes optional audio). No server needed.
  func renderHtml(args: [String: Any], result: @escaping FlutterResult) {
    let html = args["html"] as? String
    let urlString = args["url"] as? String
    let width = evenDimension((args["width"] as? Int) ?? 1080)
    let height = evenDimension((args["height"] as? Int) ?? 1920)
    let fps = max(1, min(60, (args["fps"] as? Int) ?? 30))
    let durationMs = max(200, min(120_000, (args["durationMs"] as? Int) ?? 5000))
    let audioPath = args["audioPath"] as? String
    let frameCount = max(1, Int((Double(durationMs) / 1000.0 * Double(fps)).rounded()))
    let frameInterval = 1.0 / Double(fps)

    if (html == nil || html!.isEmpty) && (urlString == nil || urlString!.isEmpty) {
      result(
        FlutterError(code: "invalid_arguments", message: "Provide html or url.", details: nil))
      return
    }

    let capturer = HtmlFrameCapturer(width: width, height: height)
    // Keep a strong reference alive for the duration of the render.
    self.htmlCapturer = capturer

    let onReady: (Bool) -> Void = { [weak self] ok in
      guard let self = self else { return }
      guard ok else {
        capturer.cleanup()
        self.htmlCapturer = nil
        result(
          FlutterError(code: "render_failed", message: "The page failed to load.", details: nil))
        return
      }

      // Phase 1 — capture frames in real time (main thread) as JPEG data so
      // memory stays bounded regardless of clip length.
      var frames: [Data] = []
      frames.reserveCapacity(frameCount)
      let start = CACurrentMediaTime()

      func captureNext(_ index: Int) {
        if self.isCancelled {
          capturer.cleanup()
          self.htmlCapturer = nil
          result(FlutterError(code: "cancelled", message: "Render was cancelled.", details: nil))
          return
        }
        if index >= frameCount {
          capturer.cleanup()
          self.htmlCapturer = nil
          // Phase 2 — encode off the main thread.
          self.workQueue.async {
            self.encodeHtmlFrames(
              frames, width: width, height: height, fps: fps, durationMs: durationMs,
              audioPath: audioPath, result: result)
          }
          return
        }
        capturer.snapshot { cg in
          if let cg = cg, let data = self.jpegData(from: cg) {
            frames.append(data)
          }
          let target = start + Double(index + 1) * frameInterval
          let delay = max(0, target - CACurrentMediaTime())
          DispatchQueue.main.asyncAfter(deadline: .now() + delay) { captureNext(index + 1) }
        }
      }
      captureNext(0)
    }

    if let html = html, !html.isEmpty {
      capturer.load(html: html, onReady: onReady)
    } else if let urlString = urlString, let url = URL(string: urlString) {
      capturer.load(url: url, onReady: onReady)
    } else {
      capturer.cleanup()
      self.htmlCapturer = nil
      result(FlutterError(code: "invalid_arguments", message: "Invalid url.", details: nil))
    }
  }

  private func encodeHtmlFrames(
    _ frames: [Data], width: Int, height: Int, fps: Int, durationMs: Int,
    audioPath: String?, result: @escaping FlutterResult
  ) {
    let durationSeconds = max(1, Int((Double(durationMs) / 1000.0).rounded()))
    do {
      let tmp = FileManager.default.temporaryDirectory
      let videoURL = tmp.appendingPathComponent("stillora_html_\(UUID().uuidString).mp4")
      let writer = try AVAssetWriter(outputURL: videoURL, fileType: .mp4)
      let settings: [String: Any] = [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: width,
        AVVideoHeightKey: height,
      ]
      let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
      input.expectsMediaDataInRealTime = false
      let adaptor = AVAssetWriterInputPixelBufferAdaptor(
        assetWriterInput: input,
        sourcePixelBufferAttributes: [
          kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
          kCVPixelBufferWidthKey as String: width,
          kCVPixelBufferHeightKey as String: height,
        ])
      writer.add(input)
      guard writer.startWriting() else { throw EngineError.write }
      writer.startSession(atSourceTime: .zero)

      for (index, data) in frames.enumerated() {
        guard let cg = cgImage(from: data),
          let buffer = pixelBuffer(from: cg, width: width, height: height, fill: true)
        else { continue }
        while !input.isReadyForMoreMediaData { usleep(3000) }
        let time = CMTime(value: CMTimeValue(index), timescale: CMTimeScale(fps))
        adaptor.append(buffer, withPresentationTime: time)
      }
      input.markAsFinished()
      let semaphore = DispatchSemaphore(value: 0)
      writer.finishWriting { semaphore.signal() }
      semaphore.wait()

      if writer.status != .completed {
        throw writer.error ?? EngineError.write
      }

      var outputURL = videoURL
      if let audioPath = audioPath, FileManager.default.fileExists(atPath: audioPath) {
        let muxed = tmp.appendingPathComponent("stillora_html_av_\(UUID().uuidString).mp4")
        try mux(
          videoURL: videoURL, audioURL: URL(fileURLWithPath: audioPath),
          duration: durationSeconds, to: muxed)
        outputURL = muxed
      }

      result([
        "outputPath": outputURL.path, "width": width, "height": height,
        "durationSeconds": durationSeconds,
      ])
    } catch {
      result(FlutterError(code: "render_failed", message: error.localizedDescription, details: nil))
    }
  }

  private func jpegData(from cgImage: CGImage) -> Data? {
    let data = NSMutableData()
    guard
      let dest = CGImageDestinationCreateWithData(
        data as CFMutableData, "public.jpeg" as CFString, 1, nil)
    else { return nil }
    CGImageDestinationAddImage(
      dest, cgImage, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
    guard CGImageDestinationFinalize(dest) else { return nil }
    return data as Data
  }

  private func cgImage(from data: Data) -> CGImage? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
  }
}

/// Offscreen WKWebView that loads a page and hands back per-frame snapshots.
final class HtmlFrameCapturer: NSObject, WKNavigationDelegate {
  private let window: NSWindow
  private let webView: WKWebView
  private var onReady: ((Bool) -> Void)?
  private var finished = false

  init(width: Int, height: Int) {
    let rect = NSRect(x: 0, y: 0, width: width, height: height)
    let config = WKWebViewConfiguration()
    webView = WKWebView(frame: rect, configuration: config)
    webView.setValue(false, forKey: "drawsBackground")
    // A borderless window keeps the web content in a live view hierarchy (so it
    // actually paints) while sitting far off-screen.
    window = NSWindow(
      contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
    super.init()
    window.contentView = webView
    window.setFrameOrigin(NSPoint(x: -20000, y: -20000))
    window.orderFrontRegardless()
    webView.navigationDelegate = self
  }

  func load(html: String, onReady: @escaping (Bool) -> Void) {
    self.onReady = onReady
    scheduleTimeout()
    webView.loadHTMLString(html, baseURL: nil)
  }

  func load(url: URL, onReady: @escaping (Bool) -> Void) {
    self.onReady = onReady
    scheduleTimeout()
    webView.load(URLRequest(url: url))
  }

  private func scheduleTimeout() {
    // Fire ready even if didFinish never arrives (pages that hold connections).
    DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
      self?.signalReady(true)
    }
  }

  private func signalReady(_ ok: Bool) {
    guard !finished else { return }
    finished = true
    let cb = onReady
    onReady = nil
    cb?(ok)
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    // Give scripts, web fonts and first paint a moment to settle.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
      self?.signalReady(true)
    }
  }

  func webView(
    _ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error
  ) {
    signalReady(false)
  }

  func webView(
    _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
  ) {
    signalReady(false)
  }

  func snapshot(_ completion: @escaping (CGImage?) -> Void) {
    let config = WKSnapshotConfiguration()
    config.rect = webView.bounds
    config.afterScreenUpdates = true
    webView.takeSnapshot(with: config) { image, _ in
      guard let image = image else { completion(nil); return }
      var rect = NSRect(origin: .zero, size: image.size)
      completion(image.cgImage(forProposedRect: &rect, context: nil, hints: nil))
    }
  }

  func cleanup() {
    window.orderOut(nil)
    webView.navigationDelegate = nil
  }
}
