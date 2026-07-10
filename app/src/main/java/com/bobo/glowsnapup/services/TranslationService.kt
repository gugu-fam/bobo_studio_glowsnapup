package com.bobo.glowsnapup.services

import android.content.Context
import org.tensorflow.lite.Interpreter
import java.io.File
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import kotlin.math.min

data class TranslationResult(val text: String, val tokens: Int)

/**
 * TranslationService
 * - loadTranslationModel: loads a TFLite model from files/models/{pair}/{version}/model.tflite
 * - translateText: simple pipeline: tokenize -> run interpreter -> detokenize
 *
 * Note: SentencePiece tokenizer is not implemented here; a placeholder tokenization is used.
 */
class TranslationService(private val context: Context) {
    private var interpreter: Interpreter? = null
    private var maxOutputTokens = 256

    suspend fun loadTranslationModel(pair: String, version: String) {
        val modelFile = File(context.filesDir, "models/$pair/$version/model.tflite")
        if (!modelFile.exists()) throw IllegalArgumentException("model not found: ${modelFile.absolutePath}")

        val fc = FileInputStream(modelFile).channel
        val size = fc.size()
        val buffer = fc.map(FileChannel.MapMode.READ_ONLY, 0, size)
        interpreter?.close()
        interpreter = Interpreter(buffer)
    }

    private fun tokenize(input: String, maxLen: Int = 256): IntArray {
        // Placeholder tokenization: split on space and map to small ints
        val parts = input.trim().split(Regex("\\s+"))
        val tokens = IntArray(min(parts.size, maxLen))
        for (i in tokens.indices) {
            tokens[i] = (parts[i].hashCode() and 0x7fffffff) % 10000 // simple hash-based token id
        }
        return tokens
    }

    private fun detokenize(ids: IntArray): String {
        // Placeholder detokenize: join ids as pseudo-words
        return ids.joinToString(" ") { "tok${it}" }
    }

    suspend fun translateText(input: String, from: String?, to: String): TranslationResult {
        val interp = interpreter ?: throw IllegalStateException("translation model not loaded")
        val inIds = tokenize(input, maxOutputTokens)

        // TFLite usually expects [1,seq] input and outputs [1,seq]
        val inputArray = Array(1) { inIds }
        val outIds = Array(1) { IntArray(maxOutputTokens) }

        interp.run(inputArray, outIds)

        val out = outIds[0]
        val text = detokenize(out)
        return TranslationResult(text, out.size)
    }
}

