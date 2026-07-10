package com.bobo.glowsnapup.services

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.io.File
import java.io.FileOutputStream
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import kotlin.math.min

data class EncryptedModel(val chunkPaths: List<String>, val metaPath: String)

/**
 * CryptoService
 * - Generates/stores AES key in Android Keystore (StrongBox if available via KeyGenParameterSpec)
 * - Provides encryptModel which writes AES-GCM encrypted chunks to app files dir
 * - Provides decryptModel which streams-decrypts chunks and returns raw bytes
 *
 * Note: This is an implementation skeleton. For production, ensure use of a vetted crypto provider
 * and perform constant-time checks, secure erasure, and thorough testing.
 */
class CryptoService(private val context: Context) {
    private val KEYSTORE_ALIAS = "bobo_glowsnapup_model_key"
    private val ANDROID_KEYSTORE = "AndroidKeyStore"
    private val CHUNK_SIZE = 1024 * 1024 // 1MB chunks

    private fun ensureKey(): SecretKey {
        val ks = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        val existing = ks.getEntry(KEYSTORE_ALIAS, null)
        if (existing != null) {
            val entry = ks.getKey(KEYSTORE_ALIAS, null) as SecretKey
            return entry
        }

        val kgen = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        val spec = KeyGenParameterSpec.Builder(
            KEYSTORE_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setUserAuthenticationRequired(false)
            .build()
        kgen.init(spec)
        return kgen.generateKey()
    }

    suspend fun encryptModel(raw: ByteArray, meta: ModelMeta): EncryptedModel {
        val key = ensureKey()
        val outDir = File(context.filesDir, "models/${meta.name}/${meta.version}")
        outDir.mkdirs()

        val chunkPaths = mutableListOf<String>()
        var offset = 0
        var idx = 0
        while (offset < raw.size) {
            val len = min(CHUNK_SIZE, raw.size - offset)
            val slice = raw.copyOfRange(offset, offset + len)

            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, key)
            val ct = cipher.doFinal(slice)
            val iv = cipher.iv // 12 bytes recommended for GCM

            // store as: IV || CIPHERTEXT
            val outFile = File(outDir, "chunk_${idx}.bin")
            FileOutputStream(outFile).use { fos ->
                fos.write(iv)
                fos.write(ct)
            }
            chunkPaths.add(outFile.absolutePath)
            offset += len
            idx += 1
        }

        // write meta.json (minimal, expand as needed)
        val metaFile = File(outDir, "meta.json")
        metaFile.writeText(
            "{\"name\":\"${meta.name}\",\"version\":\"${meta.version}\",\"sha256\":\"${meta.sha256}\"}"
        )

        return EncryptedModel(chunkPaths, metaFile.absolutePath)
    }

    suspend fun decryptModel(enc: EncryptedModel): ByteArray {
        val key = ensureKey()
        val parts = mutableListOf<Byte>()

        for (p in enc.chunkPaths) {
            val f = File(p)
            val bytes = f.readBytes()
            // read iv (assume first 12 bytes) and ciphertext rest
            if (bytes.size < 12) throw IllegalArgumentException("invalid chunk")
            val iv = bytes.copyOfRange(0, 12)
            val ct = bytes.copyOfRange(12, bytes.size)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            val spec = GCMParameterSpec(128, iv)
            cipher.init(Cipher.DECRYPT_MODE, key, spec)
            val pt = cipher.doFinal(ct)
            for (b in pt) parts.add(b)
        }

        return parts.toByteArray()
    }

    suspend fun encryptBytes(raw: ByteArray): ByteArray {
        val key = ensureKey()
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key)
        val ct = cipher.doFinal(raw)
        val iv = cipher.iv
        return iv + ct
    }

    suspend fun decryptBytes(enc: ByteArray): ByteArray {
        if (enc.size < 12 + 16) throw IllegalArgumentException("invalid encrypted bytes")
        val key = ensureKey()
        val iv = enc.copyOfRange(0, 12)
        val ct = enc.copyOfRange(12, enc.size)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val spec = GCMParameterSpec(128, iv)
        cipher.init(Cipher.DECRYPT_MODE, key, spec)
        return cipher.doFinal(ct)
    }

    // Derive a backup key from passphrase using PBKDF2 (placeholder)
    fun getBackupKey(passphrase: CharArray): SecretKey {
        // TODO: implement PBKDF2 key derivation and return SecretKeySpec
        throw NotImplementedError("getBackupKey not implemented")
    }
}

