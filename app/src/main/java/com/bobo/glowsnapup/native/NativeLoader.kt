package com.bobo.glowsnapup.native

import java.nio.ByteBuffer

class NativeLoaderException(message: String): Exception(message)

object NativeLoader {
    init {
        System.loadLibrary("native_loader")
    }

    external fun loadModelFromEncryptedChunks(chunkPaths: Array<String>, keyBytes: ByteArray): Long
    external fun getModelByteBuffer(handle: Long): ByteBuffer?
    external fun freeModelHandle(handle: Long)

    fun load(chunkPaths: Array<String>, key: ByteArray): Long {
        val h = loadModelFromEncryptedChunks(chunkPaths, key)
        if (h == 0L) throw NativeLoaderException("failed to load model")
        return h
    }
}
