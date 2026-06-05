package com.tecnoblocks.stillora_video_engine

import android.graphics.Bitmap
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
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
 * Renders a still [Bitmap] into an H.264 MP4 (video-only) using a MediaCodec input surface driven
 * by OpenGL ES. Returns the index/format of the encoded video track via the supplied [MediaMuxer]
 * so audio can be muxed into the same file.
 */
internal class StilloraGlExporter(
    private val isCancelled: () -> Boolean,
    private val onProgress: (Double) -> Unit,
) {
    fun encodeStillImage(
        bitmap: Bitmap,
        width: Int,
        height: Int,
        durationSeconds: Int,
        fill: Boolean,
        outputPath: String,
    ) {
        val fps = 30
        val bitRate = (width * height * fps * 0.12).toInt().coerceAtLeast(2_000_000)

        val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height)
        format.setInteger(
            MediaFormat.KEY_COLOR_FORMAT,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface,
        )
        format.setInteger(MediaFormat.KEY_BIT_RATE, bitRate)
        format.setInteger(MediaFormat.KEY_FRAME_RATE, fps)
        format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)

        val encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        val inputSurface = encoder.createInputSurface()
        val egl = EglCore(inputSurface)
        val renderer = BitmapRenderer(bitmap, width, height, fill)
        encoder.start()

        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var trackIndex = -1
        var muxerStarted = false
        val bufferInfo = MediaCodec.BufferInfo()
        val totalFrames = durationSeconds * fps

        try {
            for (frame in 0 until totalFrames) {
                if (isCancelled()) throw ExportCancelledException()
                drainEncoder(encoder, muxer, bufferInfo, endOfStream = false) { index, started ->
                    trackIndex = index
                    muxerStarted = started
                }
                renderer.draw()
                val presentationNs = frame.toLong() * 1_000_000_000L / fps
                egl.setPresentationTime(presentationNs)
                egl.swapBuffers()
                if (frame % 15 == 0) {
                    onProgress(0.1 + (frame.toDouble() / totalFrames) * 0.7)
                }
            }
            encoder.signalEndOfInputStream()
            drainEncoder(encoder, muxer, bufferInfo, endOfStream = true) { index, started ->
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
        }
    }

    private inline fun drainEncoder(
        encoder: MediaCodec,
        muxer: MediaMuxer,
        bufferInfo: MediaCodec.BufferInfo,
        endOfStream: Boolean,
        onMuxerState: (trackIndex: Int, started: Boolean) -> Unit,
    ) {
        val timeoutUs = if (endOfStream) 10_000L else 0L
        var trackIndex = -1
        var muxerStarted = false
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
                val encoded = encoder.getOutputBuffer(status) ?: continue
                if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                    bufferInfo.size = 0
                }
                if (bufferInfo.size != 0 && muxerStarted) {
                    encoded.position(bufferInfo.offset)
                    encoded.limit(bufferInfo.offset + bufferInfo.size)
                    muxer.writeSampleData(trackIndex, encoded, bufferInfo)
                }
                encoder.releaseOutputBuffer(status, false)
                if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
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
    fill: Boolean,
) {
    private val program: Int
    private val positionHandle: Int
    private val texCoordHandle: Int
    private val textureHandle: Int
    private val textureId: Int
    private val vertexBuffer: FloatBuffer

    init {
        program = buildProgram(VERTEX_SHADER, FRAGMENT_SHADER)
        positionHandle = GLES20.glGetAttribLocation(program, "aPosition")
        texCoordHandle = GLES20.glGetAttribLocation(program, "aTexCoord")
        textureHandle = GLES20.glGetUniformLocation(program, "uTexture")

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
        vertexBuffer = ByteBuffer.allocateDirect(vertices.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply {
                put(vertices)
                position(0)
            }

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
