package com.bobo.glowsnapup.services

import android.graphics.Bitmap
import androidx.camera.core.ImageProxy
import java.nio.ByteBuffer
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.gpu.GpuDelegate

data class InferenceResult(val mask: ByteArray?, val boxes: List<FloatArray>?, val labels: List<String>?, val scores: List<Float>?)

data class InferenceConfig(var preferNNAPI: Boolean = true, var threads: Int = 4, var tileSize: Int = 256, var preferGPU: Boolean = false)

class InferenceService(private val config: InferenceConfig = InferenceConfig()) {
    private var interpreter: Interpreter? = null
    private var gpuDelegate: GpuDelegate? = null

    suspend fun loadModel(buffer: ByteBuffer, preferNNAPI: Boolean = true) {
        // Initialize interpreter with options and delegates
        val opts = Interpreter.Options()
        opts.setNumThreads(config.threads)
        if (preferNNAPI) {
            opts.setUseNNAPI(true)
        }

        if (config.preferGPU) {
            try {
                gpuDelegate = GpuDelegate()
                opts.addDelegate(gpuDelegate)
            } catch (e: Exception) {
                // fallback
                gpuDelegate = null
            }
        }

        interpreter = Interpreter(buffer, opts)
    }

    private fun imageProxyToInputBuffer(frame: ImageProxy, tileSize: Int): ByteBuffer {
        // Placeholder: real implementation should convert ImageProxy -> FloatBuffer normalized [-1,1] or as required
        // For now return a zeroed ByteBuffer of expected size
        val bb = ByteBuffer.allocateDirect(4 * tileSize * tileSize * 3)
        bb.rewind()
        return bb
    }

    suspend fun runOnFrame(frame: ImageProxy): InferenceResult {
        val interp = interpreter ?: throw IllegalStateException("interpreter not loaded")
        val input = imageProxyToInputBuffer(frame, config.tileSize)
        // Placeholder outputs: adapt to model outputs
        val maskOut = Array(1) { Array(config.tileSize) { FloatArray(config.tileSize) } }
        interp.run(input, maskOut)

        // convert maskOut to byte array (simple threshold)
        val maskBytes = ByteArray(config.tileSize * config.tileSize)
        for (y in 0 until config.tileSize) {
            for (x in 0 until config.tileSize) {
                val v = maskOut[0][y][x]
                maskBytes[y * config.tileSize + x] = if (v > 0.5f) 255.toByte() else 0.toByte()
            }
        }

        return InferenceResult(maskBytes, null, null, null)
    }

    suspend fun runOnTiles(bitmap: Bitmap, tileSize: Int = config.tileSize): InferenceResult {
        val interp = interpreter ?: throw IllegalStateException("interpreter not loaded")
        // naive tiling: for brevity, only run center tile in this skeleton
        val w = bitmap.width
        val h = bitmap.height
        val x = maxOf(0, (w - tileSize) / 2)
        val y = maxOf(0, (h - tileSize) / 2)
        val tile = Bitmap.createBitmap(bitmap, x, y, minOf(tileSize, w - x), minOf(tileSize, h - y))

        // convert tile to ByteBuffer (placeholder)
        val input = ByteBuffer.allocateDirect(4 * tileSize * tileSize * 3)
        val maskOut = Array(1) { Array(tileSize) { FloatArray(tileSize) } }
        interp.run(input, maskOut)

        val maskBytes = ByteArray(tileSize * tileSize)
        for (yy in 0 until tileSize) for (xx in 0 until tileSize) {
            maskBytes[yy * tileSize + xx] = if (maskOut[0][yy][xx] > 0.5f) 255.toByte() else 0.toByte()
        }

        return InferenceResult(maskBytes, null, null, null)
    }

    fun unloadModel() {
        interpreter?.close()
        interpreter = null
        gpuDelegate?.close()
        gpuDelegate = null
    }
}

