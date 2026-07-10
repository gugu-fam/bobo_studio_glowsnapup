package com.bobo.glowsnapup.services

import android.content.Context
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.concurrent.Executors

data class CameraConfig(val useFront: Boolean = false, val resolutionWidth: Int = 1280, val resolutionHeight: Int = 720)

class CameraService(private val context: Context, private val config: CameraConfig = CameraConfig()) {
    private var cameraProvider: ProcessCameraProvider? = null
    private val analysisExecutor = Executors.newSingleThreadExecutor()
    private var analyzing = false
    private var lastAnalysisTs = 0L

    fun isCameraAvailable(): Boolean {
        // Basic check: camera provider available
        return try {
            ProcessCameraProvider.getInstance(context) != null
            true
        } catch (e: Exception) {
            false
        }
    }

    suspend fun init(previewView: PreviewView, lifecycleOwner: LifecycleOwner, onFrame: suspend (ImageProxy) -> Unit) {
        val provider = ProcessCameraProvider.getInstance(context).get()
        cameraProvider = provider

        val preview = Preview.Builder()
            .setTargetResolution(android.util.Size(config.resolutionWidth, config.resolutionHeight))
            .build()

        preview.setSurfaceProvider(previewView.surfaceProvider)

        val selector = if (config.useFront) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA

        val imageAnalysis = ImageAnalysis.Builder()
            .setTargetResolution(android.util.Size(config.resolutionWidth, config.resolutionHeight))
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()

        val scope = CoroutineScope(Dispatchers.Default)

        imageAnalysis.setAnalyzer(analysisExecutor) { imageProxy: ImageProxy ->
            // throttle using ThermalGuard
            val throttleMs = ThermalGuard().getThrottleMs()
            val now = System.currentTimeMillis()
            if (now - lastAnalysisTs >= throttleMs) {
                lastAnalysisTs = now
                // dispatch to coroutine for suspend onFrame
                scope.launch {
                    try {
                        onFrame(imageProxy)
                    } catch (e: Exception) {
                        // swallow; caller should log
                    } finally {
                        imageProxy.close()
                    }
                }
            } else {
                imageProxy.close()
            }
        }

        try {
            provider.unbindAll()
            provider.bindToLifecycle(lifecycleOwner, selector, preview, imageAnalysis)
        } catch (e: Exception) {
            // Surface or binding error
            throw e
        }
    }

    fun stop() {
        cameraProvider?.unbindAll()
        analysisExecutor.shutdownNow()
    }
}

