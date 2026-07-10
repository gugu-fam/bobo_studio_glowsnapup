package com.bobo.glowsnapup.services

import android.content.Context
import android.net.Uri
import java.io.File
import java.io.InputStream
import java.security.MessageDigest
import java.util.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

data class ModelMeta(val name: String, val version: String, val size: Long, val sha256: String, val signature: String?, val createdAt: Long)

/**
 * ModelManager
 * - importFromUri: read model bytes from given Uri, validate magic (TFLite: "TFL3"), compute sha256,
 *   encrypt via CryptoService into files/models/{name}/{version}/ and write meta.json
 * - listModels: read models directory and parse meta.json
 * - deleteModel: delete model directory
 * - applyDeltaUpdate: placeholder (bsdiff not implemented)
 */
class ModelManager(private val context: Context, private val crypto: CryptoService) {
    private val baseDir: File = File(context.filesDir, "models")

    suspend fun importFromUri(uri: Uri, displayName: String): ModelMeta = withContext(Dispatchers.IO) {
        val resolver = context.contentResolver
        val tmpBytes = resolver.openInputStream(uri)?.use { it.readBytes() }
            ?: throw IllegalArgumentException("unable to read uri")

        // magic number check for TFLite - first 4 bytes 'TFL3'
        if (tmpBytes.size < 4 || !(tmpBytes[0] == 'T'.code.toByte() && tmpBytes[1] == 'F'.code.toByte() && tmpBytes[2] == 'L'.code.toByte() && tmpBytes[3] == '3'.code.toByte())) {
            throw IllegalArgumentException("unsupported model format: missing TFL3 magic")
        }

        val sha256 = MessageDigest.getInstance("SHA-256").digest(tmpBytes).joinToString("") { "%02x".format(it) }
        val version = sha256.substring(0, 12)
        val name = displayName.replace(Regex("[^a-zA-Z0-9_-]"), "_")
        val meta = ModelMeta(name, version, tmpBytes.size.toLong(), sha256, null, System.currentTimeMillis())

        // encrypt and write chunks via CryptoService
        val enc = crypto.encryptModel(tmpBytes, meta)

        // store a registry meta in models/{name}/{version}/meta.json already written by CryptoService
        // return ModelMeta
        return@withContext meta
    }

    suspend fun listModels(): List<ModelMeta> = withContext(Dispatchers.IO) {
        val out = mutableListOf<ModelMeta>()
        if (!baseDir.exists()) return@withContext out
        baseDir.listFiles()?.forEach { nameDir ->
            if (!nameDir.isDirectory) return@forEach
            nameDir.listFiles()?.forEach { versionDir ->
                if (!versionDir.isDirectory) return@forEach
                val metaFile = File(versionDir, "meta.json")
                if (!metaFile.exists()) return@forEach
                try {
                    val text = metaFile.readText()
                    // very small json parse (avoid adding dependency)
                    val name = Regex("\"name\":\"(.*?)\"").find(text)?.groups?.get(1)?.value ?: nameDir.name
                    val version = Regex("\"version\":\"(.*?)\"").find(text)?.groups?.get(1)?.value ?: versionDir.name
                    val sha = Regex("\"sha256\":\"(.*?)\"").find(text)?.groups?.get(1)?.value ?: ""
                    val size = versionDir.listFiles()?.filter { it.name.startsWith("chunk_") }?.map { it.length() }?.sum() ?: 0L
                    out.add(ModelMeta(name, version, size, sha, null, versionDir.lastModified()))
                } catch (e: Exception) {
                    // skip malformed
                }
            }
        }
        return@withContext out
    }

    suspend fun deleteModel(name: String, version: String): Boolean = withContext(Dispatchers.IO) {
        val dir = File(baseDir, "$name/$version")
        if (!dir.exists()) return@withContext false
        fun deleteRec(f: File) {
            if (f.isDirectory) f.listFiles()?.forEach { deleteRec(it) }
            f.delete()
        }
        deleteRec(dir)
        return@withContext true
    }

    suspend fun applyDeltaUpdate(name: String, baseVersion: String, deltaBlob: ByteArray): Boolean = withContext(Dispatchers.IO) {
        // TODO: implement bsdiff/bspatch; for now, not implemented
        throw NotImplementedError("applyDeltaUpdate requires bsdiff/bspatch implementation")
    }
}

