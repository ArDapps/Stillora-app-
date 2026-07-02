package com.tecnoblocks.stillora_video_engine

import android.graphics.Bitmap
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLSurface
import android.opengl.GLES20
import android.opengl.GLUtils
import android.view.Surface
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

/**
 * Renders still [Bitmap] frames into an H.264 MP4 (video-only) using a MediaCodec input surface
 * driven by OpenGL ES. Multiple bitmaps are spread evenly across the requested duration.
 */
internal class StilloraGlExporter(
    private val isCancelled: () -> Boolean,
    private val onProgress: (Double) -> Unit,
) {
    // Prefer HEVC/H.265 when the device has a HARDWARE encoder for it (much
    // smaller files at the same quality). Google's software HEVC encoder
    // (c2.android.* / OMX.google.*) stalls with a GL surface input, so we skip
    // it and fall back to H.264/AVC — whose hardware encoder is universal.
    private fun videoMime(): String {
        val hevc = MediaFormat.MIMETYPE_VIDEO_HEVC
        val hasHardwareHevc =
            MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos.any { info ->
                if (!info.isEncoder) return@any false
                if (!info.supportedTypes.any { it.equals(hevc, ignoreCase = true) }) {
                    return@any false
                }
                val name = info.name.lowercase()
                !name.startsWith("c2.android.") && !name.startsWith("omx.google.")
            }
        return if (hasHardwareHevc) hevc else MediaFormat.MIMETYPE_VIDEO_AVC
    }

    fun encodeStillImage(
        bitmap: Bitmap,
        width: Int,
        height: Int,
        durationSeconds: Int,
        fill: Boolean,
        outputPath: String,
    ) = encodeStillImages(listOf(bitmap), width, height, durationSeconds, fill, outputPath)

    fun encodeStillImages(
        bitmaps: List<Bitmap>,
        width: Int,
        height: Int,
        durationSeconds: Int,
        fill: Boolean,
        outputPath: String,
    ) {
        require(bitmaps.isNotEmpty()) { "At least one bitmap is required." }

        val fps = 30
        // HEVC needs far fewer bits than H.264 for the same quality, so it gets
        // a lower bits-per-pixel target.
        val mime = videoMime()
        val bitRate =
            (width * height * fps *
                if (mime == MediaFormat.MIMETYPE_VIDEO_HEVC) 0.06 else 0.10)
                .toInt()
                .coerceAtLeast(1_200_000)

        val format = MediaFormat.createVideoFormat(mime, width, height)
        format.setInteger(
            MediaFormat.KEY_COLOR_FORMAT,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface,
        )
        format.setInteger(MediaFormat.KEY_BIT_RATE, bitRate)
        // Variable bitrate: static slideshow frames cost almost nothing instead
        // of being padded to the full bitrate, so files shrink dramatically with
        // no visible quality loss.
        format.setInteger(
            MediaFormat.KEY_BITRATE_MODE,
            MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR,
        )
        format.setInteger(MediaFormat.KEY_FRAME_RATE, fps)
        // One keyframe every 2s (was every 1s) — far fewer full frames, much
        // smaller output, still seekable.
        format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 2)

        val encoder = MediaCodec.createEncoderByType(mime)
        encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        val inputSurface = encoder.createInputSurface()
        val egl = EglCore(inputSurface)
        val renderers = bitmaps.map { bitmap -> BitmapRenderer(bitmap, width, height, fill) }
        encoder.start()

        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var trackIndex = -1
        var muxerStarted = false
        val bufferInfo = MediaCodec.BufferInfo()
        val totalFrames = durationSeconds.coerceAtLeast(1) * fps

        try {
            for (frame in 0 until totalFrames) {
                if (isCancelled()) throw ExportCancelledException()
                drainEncoder(
                    encoder,
                    muxer,
                    bufferInfo,
                    endOfStream = false,
                    currentTrackIndex = trackIndex,
                    currentMuxerStarted = muxerStarted,
                ) { index, started ->
                    trackIndex = index
                    muxerStarted = started
                }
                val rendererIndex = minOf(renderers.size - 1, frame * renderers.size / totalFrames)
                renderers[rendererIndex].draw()
                val presentationNs = frame.toLong() * 1_000_000_000L / fps
                egl.setPresentationTime(presentationNs)
                egl.swapBuffers()
                if (frame % 15 == 0) {
                    onProgress(0.1 + (frame.toDouble() / totalFrames) * 0.7)
                }
            }
            encoder.signalEndOfInputStream()
            drainEncoder(
                encoder,
                muxer,
                bufferInfo,
                endOfStream = true,
                currentTrackIndex = trackIndex,
                currentMuxerStarted = muxerStarted,
            ) { index, started ->
                trackIndex = index
                muxerStarted = started
            }
        } finally {
            try {
                encoder.stop()
            } catch (_: Exception) {
            }
            encoder.release()
            renderers.forEach { renderer -> renderer.release() }
            egl.release()
            try {
                if (muxerStarted) muxer.stop()
            } catch (_: Exception) {
            }
            muxer.release()
        }
    }

    fun encodeTimeline(
        media: List<StilloraTimelineMedia>,
        width: Int,
        height: Int,
        durationSeconds: Int,
        fill: Boolean,
        outputPath: String,
    ) {
        require(media.isNotEmpty()) { "At least one media item is required." }

        val sources = media.mapNotNull { it.open() }
        require(sources.isNotEmpty()) { "At least one readable media item is required." }

        val firstFrame = sources.firstNotNullOfOrNull { source ->
            source.frameAt(localFrame = 0, segmentFrames = 1)
        } ?: throw IllegalArgumentException("The selected media could not be rendered.")

        val fps = 30
        // HEVC needs far fewer bits than H.264 for the same quality, so it gets
        // a lower bits-per-pixel target.
        val mime = videoMime()
        val bitRate =
            (width * height * fps *
                if (mime == MediaFormat.MIMETYPE_VIDEO_HEVC) 0.06 else 0.10)
                .toInt()
                .coerceAtLeast(1_200_000)

        val format = MediaFormat.createVideoFormat(mime, width, height)
        format.setInteger(
            MediaFormat.KEY_COLOR_FORMAT,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface,
        )
        format.setInteger(MediaFormat.KEY_BIT_RATE, bitRate)
        // Variable bitrate: static slideshow frames cost almost nothing instead
        // of being padded to the full bitrate, so files shrink dramatically with
        // no visible quality loss.
        format.setInteger(
            MediaFormat.KEY_BITRATE_MODE,
            MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR,
        )
        format.setInteger(MediaFormat.KEY_FRAME_RATE, fps)
        // One keyframe every 2s (was every 1s) — far fewer full frames, much
        // smaller output, still seekable.
        format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 2)

        val encoder = MediaCodec.createEncoderByType(mime)
        encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        val inputSurface = encoder.createInputSurface()
        val egl = EglCore(inputSurface)
        val renderer = BitmapRenderer(firstFrame.bitmap, width, height, fill)
        firstFrame.recycleIfNeeded()
        encoder.start()

        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var trackIndex = -1
        var muxerStarted = false
        val bufferInfo = MediaCodec.BufferInfo()
        val totalFrames = durationSeconds.coerceAtLeast(1) * fps

        try {
            for (frame in 0 until totalFrames) {
                if (isCancelled()) throw ExportCancelledException()
                drainEncoder(
                    encoder,
                    muxer,
                    bufferInfo,
                    endOfStream = false,
                    currentTrackIndex = trackIndex,
                    currentMuxerStarted = muxerStarted,
                ) { index, started ->
                    trackIndex = index
                    muxerStarted = started
                }

                val sourceIndex = minOf(sources.size - 1, frame * sources.size / totalFrames)
                val segmentStart = sourceIndex * totalFrames / sources.size
                val segmentEnd = (sourceIndex + 1) * totalFrames / sources.size
                val segmentFrames = (segmentEnd - segmentStart).coerceAtLeast(1)
                val localFrame = frame - segmentStart
                val timelineFrame = sources[sourceIndex].frameAt(localFrame, segmentFrames)
                if (timelineFrame != null) {
                    renderer.updateBitmap(timelineFrame.bitmap)
                    renderer.draw()
                    timelineFrame.recycleIfNeeded()
                }

                val presentationNs = frame.toLong() * 1_000_000_000L / fps
                egl.setPresentationTime(presentationNs)
                egl.swapBuffers()
                if (frame % 15 == 0) {
                    onProgress(0.1 + (frame.toDouble() / totalFrames) * 0.7)
                }
            }
            encoder.signalEndOfInputStream()
            drainEncoder(
                encoder,
                muxer,
                bufferInfo,
                endOfStream = true,
                currentTrackIndex = trackIndex,
                currentMuxerStarted = muxerStarted,
            ) { index, started ->
                trackIndex = index
                muxerStarted = started
            }
        } finally {
            try {
                encoder.stop()
            } catch (_: Exception) {
            }
            encoder.release()
            renderer.release()
            egl.release()
            try {
                if (muxerStarted) muxer.stop()
            } catch (_: Exception) {
            }
            muxer.release()
            sources.forEach { it.release() }
        }
    }

    private inline fun drainEncoder(
        encoder: MediaCodec,
        muxer: MediaMuxer,
        bufferInfo: MediaCodec.BufferInfo,
        endOfStream: Boolean,
        currentTrackIndex: Int,
        currentMuxerStarted: Boolean,
        onMuxerState: (trackIndex: Int, started: Boolean) -> Unit,
    ) {
        val timeoutUs = if (endOfStream) 10_000L else 0L
        var trackIndex = currentTrackIndex
        var muxerStarted = currentMuxerStarted
        while (true) {
            val status = encoder.dequeueOutputBuffer(bufferInfo, timeoutUs)
            if (status == MediaCodec.INFO_TRY_AGAIN_LATER) {
                if (!endOfStream) break
            } else if (status == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                trackIndex = muxer.addTrack(encoder.outputFormat)
                muxer.start()
                muxerStarted = true
                onMuxerState(trackIndex, muxerStarted)
            } else if (status >= 0) {
                val encoded = encoder.getOutputBuffer(status)
                if (encoded != null) {
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        bufferInfo.size = 0
                    }
                    if (bufferInfo.size != 0 && muxerStarted) {
                        encoded.position(bufferInfo.offset)
                        encoded.limit(bufferInfo.offset + bufferInfo.size)
                        muxer.writeSampleData(trackIndex, encoded, bufferInfo)
                    }
                }
                encoder.releaseOutputBuffer(status, false)
                if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
            }
        }
    }
}

internal sealed class StilloraTimelineMedia {
    data class Image(val bitmap: Bitmap) : StilloraTimelineMedia()
    data class Video(val path: String) : StilloraTimelineMedia()

    fun open(): TimelineSource? {
        return when (this) {
            is Image -> TimelineSource.Image(bitmap)
            is Video -> TimelineSource.Video.open(path)
        }
    }
}

internal data class TimelineFrame(val bitmap: Bitmap, val recycleAfterDraw: Boolean) {
    fun recycleIfNeeded() {
        if (recycleAfterDraw && !bitmap.isRecycled) bitmap.recycle()
    }
}

internal sealed class TimelineSource {
    abstract fun frameAt(localFrame: Int, segmentFrames: Int): TimelineFrame?
    open fun release() {}

    class Image(private val bitmap: Bitmap) : TimelineSource() {
        override fun frameAt(localFrame: Int, segmentFrames: Int): TimelineFrame {
            return TimelineFrame(bitmap, recycleAfterDraw = false)
        }
    }

    class Video private constructor(
        private val retriever: MediaMetadataRetriever,
        private val durationUs: Long,
    ) : TimelineSource() {
        override fun frameAt(localFrame: Int, segmentFrames: Int): TimelineFrame? {
            val progress = if (segmentFrames <= 1) 0.0
            else localFrame.toDouble() / (segmentFrames - 1).toDouble()
            val sourceTimeUs = (durationUs * progress)
                .toLong()
                .coerceIn(0L, (durationUs - 1).coerceAtLeast(0L))
            val bitmap = retriever.getFrameAtTime(
                sourceTimeUs,
                MediaMetadataRetriever.OPTION_CLOSEST,
            ) ?: return null
            return TimelineFrame(bitmap, recycleAfterDraw = true)
        }

        override fun release() {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }

        companion object {
            fun open(path: String): Video? {
                return try {
                    val retriever = MediaMetadataRetriever()
                    retriever.setDataSource(path)
                    val durationMs = retriever.extractMetadata(
                        MediaMetadataRetriever.METADATA_KEY_DURATION,
                    )?.toLongOrNull() ?: 1L
                    Video(retriever, (durationMs * 1_000L).coerceAtLeast(1L))
                } catch (_: Exception) {
                    null
                }
            }
        }
    }
}

/** Minimal EGL context bound to a MediaCodec input [Surface]. */
private class EglCore(surface: Surface) {
    private var display: EGLDisplay = EGL14.EGL_NO_DISPLAY
    private var context: EGLContext = EGL14.EGL_NO_CONTEXT
    private var eglSurface: EGLSurface = EGL14.EGL_NO_SURFACE

    init {
        display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
        val version = IntArray(2)
        EGL14.eglInitialize(display, version, 0, version, 1)
        val configAttribs = intArrayOf(
            EGL14.EGL_RED_SIZE, 8,
            EGL14.EGL_GREEN_SIZE, 8,
            EGL14.EGL_BLUE_SIZE, 8,
            EGL14.EGL_ALPHA_SIZE, 8,
            EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
            0x3142, 1, // EGL_RECORDABLE_ANDROID
            EGL14.EGL_NONE,
        )
        val configs = arrayOfNulls<EGLConfig>(1)
        val numConfigs = IntArray(1)
        EGL14.eglChooseConfig(display, configAttribs, 0, configs, 0, 1, numConfigs, 0)
        val contextAttribs = intArrayOf(EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL14.EGL_NONE)
        context = EGL14.eglCreateContext(
            display, configs[0], EGL14.EGL_NO_CONTEXT, contextAttribs, 0,
        )
        val surfaceAttribs = intArrayOf(EGL14.EGL_NONE)
        eglSurface = EGL14.eglCreateWindowSurface(display, configs[0], surface, surfaceAttribs, 0)
        EGL14.eglMakeCurrent(display, eglSurface, eglSurface, context)
    }

    fun setPresentationTime(nanoseconds: Long) {
        android.opengl.EGLExt.eglPresentationTimeANDROID(display, eglSurface, nanoseconds)
    }

    fun swapBuffers() {
        EGL14.eglSwapBuffers(display, eglSurface)
    }

    fun release() {
        if (display != EGL14.EGL_NO_DISPLAY) {
            EGL14.eglMakeCurrent(
                display, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT,
            )
            EGL14.eglDestroySurface(display, eglSurface)
            EGL14.eglDestroyContext(display, context)
            EGL14.eglReleaseThread()
            EGL14.eglTerminate(display)
        }
        display = EGL14.EGL_NO_DISPLAY
        context = EGL14.EGL_NO_CONTEXT
        eglSurface = EGL14.EGL_NO_SURFACE
    }
}

/** Draws a single bitmap as a textured quad, scaled for fit/fill, on a cleared background. */
private class BitmapRenderer(
    bitmap: Bitmap,
    private val targetWidth: Int,
    private val targetHeight: Int,
    private val fill: Boolean,
) {
    private val program: Int
    private val positionHandle: Int
    private val texCoordHandle: Int
    private val textureHandle: Int
    private val textureId: Int
    private var vertexBuffer: FloatBuffer

    init {
        program = buildProgram(VERTEX_SHADER, FRAGMENT_SHADER)
        positionHandle = GLES20.glGetAttribLocation(program, "aPosition")
        texCoordHandle = GLES20.glGetAttribLocation(program, "aTexCoord")
        textureHandle = GLES20.glGetUniformLocation(program, "uTexture")

        vertexBuffer = makeVertexBuffer(bitmap)

        val textures = IntArray(1)
        GLES20.glGenTextures(1, textures, 0)
        textureId = textures[0]
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR,
        )
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR,
        )
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE,
        )
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE,
        )
        GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
    }

    fun updateBitmap(bitmap: Bitmap) {
        vertexBuffer = makeVertexBuffer(bitmap)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
    }

    fun draw() {
        GLES20.glViewport(0, 0, targetWidth, targetHeight)
        GLES20.glClearColor(0.066f, 0.094f, 0.145f, 1f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
        GLES20.glUseProgram(program)

        vertexBuffer.position(0)
        GLES20.glEnableVertexAttribArray(positionHandle)
        GLES20.glVertexAttribPointer(positionHandle, 2, GLES20.GL_FLOAT, false, 16, vertexBuffer)
        vertexBuffer.position(2)
        GLES20.glEnableVertexAttribArray(texCoordHandle)
        GLES20.glVertexAttribPointer(texCoordHandle, 2, GLES20.GL_FLOAT, false, 16, vertexBuffer)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        GLES20.glUniform1i(textureHandle, 0)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GLES20.glDisableVertexAttribArray(positionHandle)
        GLES20.glDisableVertexAttribArray(texCoordHandle)
    }

    fun release() {
        GLES20.glDeleteTextures(1, intArrayOf(textureId), 0)
        GLES20.glDeleteProgram(program)
    }

    private fun buildProgram(vertexSource: String, fragmentSource: String): Int {
        val vertexShader = compileShader(GLES20.GL_VERTEX_SHADER, vertexSource)
        val fragmentShader = compileShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource)
        val program = GLES20.glCreateProgram()
        GLES20.glAttachShader(program, vertexShader)
        GLES20.glAttachShader(program, fragmentShader)
        GLES20.glLinkProgram(program)
        GLES20.glDeleteShader(vertexShader)
        GLES20.glDeleteShader(fragmentShader)
        return program
    }

    private fun compileShader(type: Int, source: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, source)
        GLES20.glCompileShader(shader)
        return shader
    }

    private fun makeVertexBuffer(bitmap: Bitmap): FloatBuffer {
        val imageAspect = bitmap.width.toFloat() / bitmap.height
        val targetAspect = targetWidth.toFloat() / targetHeight
        var scaleX = 1f
        var scaleY = 1f
        if (fill) {
            if (imageAspect > targetAspect) scaleX = imageAspect / targetAspect
            else scaleY = targetAspect / imageAspect
        } else {
            if (imageAspect > targetAspect) scaleY = targetAspect / imageAspect
            else scaleX = imageAspect / targetAspect
        }

        // x, y, u, v — texture V is flipped because bitmaps are top-down.
        val vertices = floatArrayOf(
            -scaleX, -scaleY, 0f, 1f,
            scaleX, -scaleY, 1f, 1f,
            -scaleX, scaleY, 0f, 0f,
            scaleX, scaleY, 1f, 0f,
        )
        return ByteBuffer.allocateDirect(vertices.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply {
                put(vertices)
                position(0)
            }
    }

    companion object {
        private const val VERTEX_SHADER = """
            attribute vec4 aPosition;
            attribute vec2 aTexCoord;
            varying vec2 vTexCoord;
            void main() {
                gl_Position = aPosition;
                vTexCoord = aTexCoord;
            }
        """

        private const val FRAGMENT_SHADER = """
            precision mediump float;
            varying vec2 vTexCoord;
            uniform sampler2D uTexture;
            void main() {
                gl_FragColor = texture2D(uTexture, vTexCoord);
            }
        """
    }
}

internal class ExportCancelledException : Exception("Export was cancelled.")
