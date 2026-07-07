import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bobo_studio_glowsnapup/core/storage/encrypted_store.dart';

class FakeSecureStorage {
  final Map<String, String> _store = {};

  Future<void> write({required String key, required String? value, IOSOptions? iOptions, AndroidOptions? aOptions}) async {
    if (value == null) return;
    _store[key] = value;
  }
  
  Future<String?> read({required String key, IOSOptions? iOptions, AndroidOptions? aOptions}) async {
    return _store[key];
  }

  // Other methods omitted for brevity; tests only use read/write
  
  Future<void> delete({required String key, IOSOptions? iOptions, AndroidOptions? aOptions}) async {
    _store.remove(key);
  }
  
  Future<Map<String, String>> readAll({IOSOptions? iOptions, AndroidOptions? aOptions}) async => Map.from(_store);

  Future<void> deleteAll({IOSOptions? iOptions, AndroidOptions? aOptions}) async => _store.clear();
}

void main() {
  test('save and get api key roundtrip with fake storage', () async {
    final fake = FakeSecureStorage();
    final store = EncryptedStore(fake);

    await store.saveApiKey('prov', 'secret123');
    final got = await store.getApiKey('prov');
    expect(got, 'secret123');
  });
}
