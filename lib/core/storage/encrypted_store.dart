// Path: lib/core/storage/encrypted_store.dart
// AUTO-GEN minimal EncryptedStore using flutter_secure_storage API

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptedStore {
  final FlutterSecureStorage _secure;

  EncryptedStore([FlutterSecureStorage? secure]) : _secure = secure ?? const FlutterSecureStorage();

  Future<void> saveApiKey(String provider, String apiKey) async {
    final key = 'api_key_$provider';
    await _secure.write(key: key, value: apiKey);
  }

  Future<String?> getApiKey(String provider) async {
    final key = 'api_key_$provider';
    return await _secure.read(key: key);
  }
}

