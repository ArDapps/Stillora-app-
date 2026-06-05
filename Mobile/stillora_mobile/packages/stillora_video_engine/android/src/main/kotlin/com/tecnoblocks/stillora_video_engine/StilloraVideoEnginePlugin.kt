package com.tecnoblocks.stillora_video_engine

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.nio.ByteBuffer
import java.util.UUID
import java.util.concurrent.Executors
import kotlin.math.max

/** StilloraVideoEnginePlugin */
class StilloraVideoEnginePlugin :
    FlutterPlugin,
    MethodCallHandler,
    EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var progressChannel: EventChannel
    private lateinit var appContext: Context

    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    @Volatile private var eventSink: EventChannel.EventSink? = null
    @Volatile private var cancelled = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "stillora_video_engine")
        channel.setMethodCallHandler(this)
        progressChannel = EventChannel(binding.binaryMessenger, "stillora_video_engine/progress")
        progressChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        progressChannel.setStreamHandler(null)
        executor.shutdown()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "exportVideo" -> {
                cancelled = false
                executor.execute { runExport(call, result) }
            }
            "cancelExport" -> {
                cancelled = true
                result.success(null)
            }
            "clearTemporaryFiles" -> {
                clearTemporaryFiles()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun runExport(call: MethodCall, result: Result) {
        val imagePath = call.argument<String>("imagePath") ?: ""
        val requestedMediaPaths = (call.argument<List<*>>("mediaPaths") ?: emptyList<Any>())
            .filterIsInstance<String>()
            .filter { it.isNotBlank() }
        val requestedImagePaths = (call.argument<List<*>>("imagePaths") ?: emptyList<Any>())
            .filterIsInstance<String>()
            .filter { it.isNotBlank() }
        val mediaSourcePaths =
            when {
                requestedMediaPaths.isNotEmpty() -> requestedMediaPaths
                requestedImagePaths.isNotEmpty() -> requestedImagePaths
                else -> listOf(imagePath)
            }.distinct()
        val audioPath = call.argument<String>("audioPath")
        val duration = (call.argument<Int>("durationSeconds") ?: 10).coerceIn(1, 300)
        val width = evenDimension(call.argument<Int>("width") ?: 1080)
        val height = evenDimension(call.argument<Int>("height") ?: 1920)
        val fill = (call.argument<String>("resizeMode") ?: "fit") == "fill"

        try {
            emit("preparingImage", 0.05, "Preparing media")
            val bitmaps = mutableListOf<Bitmap>()
            val timelineMedia = mutableListOf<StilloraTimelineMedia>()
            for (path in mediaSourcePaths) {
                if (isVideoFile(path)) {
                    timelineMedia.add(StilloraTimelineMedia.Video(path))
                } else {
                    decodeBitmap(path)?.let { bitmap ->
                        bitmaps.add(bitmap)
                        timelineMedia.add(StilloraTimelineMedia.Image(bitmap))
                    }
                }
            }
            if (timelineMedia.isEmpty()) {
                failOnMain(result, "missing_source", "The selected media could not be read.")
                return
            }

            val outputDir = outputDirectory()
            val finalPath = File(outputDir, "stillora-${UUID.randomUUID()}.mp4").absolutePath
            val hasAudio = !audioPath.isNullOrEmpty() && File(audioPath).exists()
            val videoPath =
                if (hasAudio) File(outputDir, "tmp-${UUID.randomUUID()}.mp4").absolutePath
                else finalPath

            val exporter = StilloraGlExporter(
                isCancelled = { cancelled },
                onProgress = { emit("generatingVideo", it, "Generating video") },
            )
            try {
                if (timelineMedia.all { it is StilloraTimelineMedia.Image }) {
                    exporter.encodeStillImages(bitmaps, width, height, duration, fill, videoPath)
                } else {
                    exporter.encodeTimeline(timelineMedia, width, height, duration, fill, videoPath)
                }
            } finally {
                bitmaps.forEach { bitmap ->
                    if (!bitmap.isRecycled) bitmap.recycle()
                }
            }

            if (cancelled) {
                File(videoPath).delete()
                failOnMain(result, "cancelled", "Export was cancelled.")
                return
            }

            if (hasAudio) {
                emit("mergingAudio", 0.85, "Merging audio")
                val merged = muxVideoAndAudio(videoPath, audioPath!!, duration, finalPath)
                if (!merged) {
                    File(videoPath).delete()
                    failOnMain(
                        result,
                        "audio_mix_failed",
                        "This audio file could not be mixed. Use M4A or AAC on Android.",
                    )
                    return
                }
                File(videoPath).delete()
            }

            emit("savingVideo", 0.95, "Saving")
            emit("done", 1.0, "Saved")
            val payload = mapOf(
                "outputPath" to finalPath,
                "width" to width,
                "height" to height,
                "durationSeconds" to duration,
            )
            mainHandler.post { result.success(payload) }
        } catch (_: ExportCancelledException) {
            failOnMain(result, "cancelled", "Export was cancelled.")
        } catch (error: Exception) {
            failOnMain(result, "export_failed", error.message ?: "Export failed.")
        }
    }

    // MARK: - Audio muxing (AAC track copy only)

    private fun muxVideoAndAudio(
        videoPath: String,
        audioPath: String,
        durationSeconds: Int,
        outputPath: String,
    ): Boolean {
        val videoExtractor = MediaExtractor()
        val audioExtractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        try {
            videoExtractor.setDataSource(videoPath)
            audioExtractor.setDataSource(audioPath)
            val videoTrack = selectTrack(videoExtractor, "video/")
            val audioTrack = selectTrack(audioExtractor, "audio/")
            if (videoTrack < 0 || audioTrack < 0) return false

            val audioFormat = audioExtractor.getTrackFormat(audioTrack)
            // MediaMuxer can only mux AAC audio into MP4 reliably.
            if (audioFormat.getString(MediaFormat.KEY_MIME) != "audio/mp4a-latm") return false

            videoExtractor.selectTrack(videoTrack)
            audioExtractor.selectTrack(audioTrack)

            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val outVideo = muxer.addTrack(videoExtractor.getTrackFormat(videoTrack))
            val outAudio = muxer.addTrack(audioFormat)
            muxer.start()

            copyTrack(videoExtractor, muxer, outVideo, Long.MAX_VALUE)
            copyTrack(audioExtractor, muxer, outAudio, durationSeconds * 1_000_000L)
            return true
        } catch (_: Exception) {
            return false
        } finally {
            try {
                muxer?.stop()
            } catch (_: Exception) {
            }
            muxer?.release()
            videoExtractor.release()
            audioExtractor.release()
        }
    }

    private fun copyTrack(
        extractor: MediaExtractor,
        muxer: MediaMuxer,
        trackIndex: Int,
        maxDurationUs: Long,
    ) {
        val buffer = ByteBuffer.allocate(1 shl 20)
        val info = android.media.MediaCodec.BufferInfo()
        while (true) {
            val size = extractor.readSampleData(buffer, 0)
            if (size < 0) break
            val time = extractor.sampleTime
            if (time > maxDurationUs) break
            info.offset = 0
            info.size = size
            info.presentationTimeUs = time
            info.flags = extractor.sampleFlags
            muxer.writeSampleData(trackIndex, buffer, info)
            extractor.advance()
        }
    }

    private fun selectTrack(extractor: MediaExtractor, prefix: String): Int {
        for (index in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(index).getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith(prefix)) return index
        }
        return -1
    }

    // MARK: - Bitmap decoding

    private fun decodeBitmap(path: String, maxDimension: Int = 2000): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        var sampleSize = 1
        while (max(bounds.outWidth, bounds.outHeight) / sampleSize > maxDimension) {
            sampleSize *= 2
        }
        val options = BitmapFactory.Options().apply { inSampleSize = sampleSize }
        val bitmap = BitmapFactory.decodeFile(path, options) ?: return null
        return applyExifRotation(path, bitmap)
    }

    private fun applyExifRotation(path: String, bitmap: Bitmap): Bitmap {
        val orientation = try {
            ExifInterface(path).getAttributeInt(
                ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL,
            )
        } catch (_: Exception) {
            ExifInterface.ORIENTATION_NORMAL
        }
        val degrees = when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> 90f
            ExifInterface.ORIENTATION_ROTATE_180 -> 180f
            ExifInterface.ORIENTATION_ROTATE_270 -> 270f
            else -> 0f
        }
        if (degrees == 0f) return bitmap
        val matrix = Matrix().apply { postRotate(degrees) }
        val rotated = Bitmap.createBitmap(
            bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true,
        )
        if (rotated != bitmap) bitmap.recycle()
        return rotated
    }

    // MARK: - Files & utilities

    private fun outputDirectory(): File {
        val dir = File(appContext.filesDir, "stillora_exports")
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    private fun clearTemporaryFiles() {
        outputDirectory().listFiles()?.forEach { file ->
            if (file.name.startsWith("tmp-")) file.delete()
        }
    }

    private fun isVideoFile(path: String): Boolean {
        val ext = path.substringAfterLast('.', "").lowercase()
        return ext in setOf("mp4", "mov", "m4v", "webm", "avi", "mkv", "3gp", "m2ts")
    }

    private fun evenDimension(value: Int): Int {
        val safe = max(2, value)
        return if (safe % 2 == 0) safe else safe + 1
    }

    private fun emit(stage: String, percentage: Double, message: String?) {
        val sink = eventSink ?: return
        val payload = mutableMapOf<String, Any>("stage" to stage, "percentage" to percentage)
        if (message != null) payload["message"] = message
        mainHandler.post { sink.success(payload) }
    }

    private fun failOnMain(result: Result, code: String, message: String) {
        mainHandler.post { result.error(code, message, null) }
    }
}
