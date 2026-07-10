// native_loader.cpp
// Responsibilities:
// - AES-GCM decrypt of stored chunks (stored as IV(12) || CIPHERTEXT||TAG(16))
// - copy decrypted bytes into anonymous mmap and mprotect(PROT_READ)
// - manage handles and expose JNI interfaces returning DirectByteBuffer

#include <jni.h>
#include <string>
#include <unordered_map>
#include <mutex>
#include <vector>
#include <sys/mman.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <fstream>
#include <openssl/evp.h>
#include <openssl/err.h>

struct ModelHandle {
    void* addr;
    size_t size;
};

static std::unordered_map<int64_t, ModelHandle> g_handles;
static std::mutex g_handles_mutex;
static int64_t g_next_handle = 1;

static void log_openssl_error() {
    unsigned long e = ERR_get_error();
    if (e) {
        char buf[256];
        ERR_error_string_n(e, buf, sizeof(buf));
    }
}

static std::vector<uint8_t> read_file_bytes(const std::string& path) {
    std::ifstream ifs(path, std::ios::binary);
    if (!ifs) return {};
    ifs.seekg(0, std::ios::end);
    size_t size = (size_t)ifs.tellg();
    ifs.seekg(0, std::ios::beg);
    std::vector<uint8_t> buf(size);
    ifs.read(reinterpret_cast<char*>(buf.data()), size);
    return buf;
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_bobo_glowsnapup_native_NativeLoader_loadModelFromEncryptedChunks(JNIEnv* env, jclass /*clazz*/, jobjectArray chunkPaths, jbyteArray keyBytes) {
    if (chunkPaths == nullptr || keyBytes == nullptr) return 0;

    jsize keyLen = env->GetArrayLength(keyBytes);
    std::vector<uint8_t> key(keyLen);
    env->GetByteArrayRegion(keyBytes, 0, keyLen, reinterpret_cast<jbyte*>(key.data()));

    // Collect decrypted bytes in a vector first
    std::vector<uint8_t> plaintext;

    jsize n = env->GetArrayLength(chunkPaths);
    for (jsize i = 0; i < n; ++i) {
        jstring jpath = (jstring)env->GetObjectArrayElement(chunkPaths, i);
        const char* cpath = env->GetStringUTFChars(jpath, nullptr);
        std::string path(cpath);
        env->ReleaseStringUTFChars(jpath, cpath);
        env->DeleteLocalRef(jpath);

        auto bytes = read_file_bytes(path);
        if (bytes.size() < 12 + 16) {
            return 0; // invalid chunk
        }

        // iv is first 12 bytes
        const uint8_t* iv = bytes.data();
        size_t iv_len = 12;

        // ciphertext + tag follows
        size_t ct_len_total = bytes.size() - iv_len;
        if (ct_len_total < 16) return 0;
        size_t tag_len = 16;
        size_t ct_len = ct_len_total - tag_len;

        const uint8_t* ct_ptr = bytes.data() + iv_len;
        const uint8_t* tag_ptr = bytes.data() + iv_len + ct_len;

        EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
        if (!ctx) {
            log_openssl_error();
            return 0;
        }

        int rc = EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), nullptr, nullptr, nullptr);
        if (rc != 1) { EVP_CIPHER_CTX_free(ctx); log_openssl_error(); return 0; }

        if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, (int)iv_len, nullptr) != 1) { EVP_CIPHER_CTX_free(ctx); log_openssl_error(); return 0; }

        if (EVP_DecryptInit_ex(ctx, nullptr, nullptr, key.data(), iv) != 1) { EVP_CIPHER_CTX_free(ctx); log_openssl_error(); return 0; }

        std::vector<uint8_t> out(ct_len);
        int outlen = 0;
        if (ct_len > 0) {
            if (EVP_DecryptUpdate(ctx, out.data(), &outlen, ct_ptr, (int)ct_len) != 1) { EVP_CIPHER_CTX_free(ctx); log_openssl_error(); return 0; }
        }

        // set tag before final
        if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, (int)tag_len, const_cast<uint8_t*>(tag_ptr)) != 1) { EVP_CIPHER_CTX_free(ctx); log_openssl_error(); return 0; }

        int finlen = 0;
        if (EVP_DecryptFinal_ex(ctx, out.data() + outlen, &finlen) != 1) { EVP_CIPHER_CTX_free(ctx); log_openssl_error(); return 0; }

        EVP_CIPHER_CTX_free(ctx);

        out.resize(outlen + finlen);
        plaintext.insert(plaintext.end(), out.begin(), out.end());
    }

    if (plaintext.empty()) return 0;

    // allocate anonymous mmap and copy plaintext
    size_t total = plaintext.size();
    void* addr = mmap(nullptr, total, PROT_READ | PROT_WRITE, MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);
    if (addr == MAP_FAILED) return 0;

    memcpy(addr, plaintext.data(), total);
    // make read-only
    if (mprotect(addr, total, PROT_READ) != 0) {
        munmap(addr, total);
        return 0;
    }

    // register handle
    int64_t handle = 0;
    {
        std::lock_guard<std::mutex> lk(g_handles_mutex);
        handle = g_next_handle++;
        g_handles[handle] = { addr, total };
    }

    return (jlong)handle;
}

extern "C" JNIEXPORT jobject JNICALL
Java_com_bobo_glowsnapup_native_NativeLoader_getModelByteBuffer(JNIEnv* env, jclass /*clazz*/, jlong handle) {
    std::lock_guard<std::mutex> lk(g_handles_mutex);
    auto it = g_handles.find((int64_t)handle);
    if (it == g_handles.end()) return nullptr;
    void* addr = it->second.addr;
    size_t size = it->second.size;
    return env->NewDirectByteBuffer(addr, (jlong)size);
}

extern "C" JNIEXPORT void JNICALL
Java_com_bobo_glowsnapup_native_NativeLoader_freeModelHandle(JNIEnv* env, jclass /*clazz*/, jlong handle) {
    (void)env;
    std::lock_guard<std::mutex> lk(g_handles_mutex);
    auto it = g_handles.find((int64_t)handle);
    if (it != g_handles.end()) {
        munmap(it->second.addr, it->second.size);
        g_handles.erase(it);
    }
}
