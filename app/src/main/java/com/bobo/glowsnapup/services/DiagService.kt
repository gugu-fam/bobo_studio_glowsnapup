package com.bobo.glowsnapup.services

import android.content.Context
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

data class DiagEvent(val timestamp: Long, val level: String, val message: String, val details: Map<String, String>?)

class DiagService(private val context: Context, private val crypto: CryptoService) {
    private val diagDir: File = File(context.filesDir, "diag").apply { mkdirs() }

    fun logEvent(event: DiagEvent) {
        // synchronous wrapper
        val ts = event.timestamp
        val sdf = SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'", Locale.US)
        sdf.timeZone = TimeZone.getTimeZone("UTC")
        val name = "diag_${sdf.format(Date(ts))}.bin"
        val json = buildJson(event)
        // encrypt and write (run in background ideally)
        try {
            val enc = kotlinx.coroutines.runBlocking { crypto.encryptBytes(json.toByteArray(Charsets.UTF_8)) }
            FileOutputStream(File(diagDir, name)).use { it.write(enc) }
        } catch (e: Exception) {
            // swallow or log to local unencrypted fallback if required
        }
    }

    private fun buildJson(event: DiagEvent): String {
        val details = event.details?.entries?.joinToString(",") { "\"${it.key}\":\"${it.value}\"" } ?: ""
        return "{\"timestamp\":${event.timestamp},\"level\":\"${event.level}\",\"message\":\"${event.message}\",\"details\":{${details}}}"
    }

    suspend fun exportLogs(targetPath: String, userConsent: Boolean) {
        if (!userConsent) throw IllegalStateException("user consent required to export diag logs")
        withContext(Dispatchers.IO) {
            val outFile = File(targetPath)
            outFile.parentFile?.mkdirs()
            FileOutputStream(outFile).use { out ->
                diagDir.listFiles()?.forEach { f ->
                    // append each encrypted file as-is
                    val bytes = f.readBytes()
                    out.write(bytes)
                }
            }
        }
    }
}

