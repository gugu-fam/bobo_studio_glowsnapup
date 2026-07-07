import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../lib/core/storage/encrypted_store.dart';

class _InMemorySecureStorage implements FlutterSecureStorage {
  final Map<String, String> _m = {};

  @override
  final AndroidOptions aOptions = const AndroidOptions();
  @override
  final IOSOptions iOptions = const IOSOptions();
  @override
  final LinuxOptions lOptions = const LinuxOptions();
  @override
  final MacOsOptions mOptions = const MacOsOptions();
  @override
  final WindowsOptions wOptions = const WindowsOptions();
  @override
  final WebOptions webOptions = const WebOptions();

  @override
  Future<void> write({required String key, required String? value, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, MacOsOptions? mOptions, WindowsOptions? wOptions, WebOptions? webOptions}) async {
    if (value == null) return;
    _m[key] = value;
  }

  @override
  Future<String?> read({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, MacOsOptions? mOptions, WindowsOptions? wOptions, WebOptions? webOptions}) async {
    return _m[key];
  }

  @override
  Future<void> delete({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, MacOsOptions? mOptions, WindowsOptions? wOptions, WebOptions? webOptions}) async {
    _m.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, MacOsOptions? mOptions, WindowsOptions? wOptions, WebOptions? webOptions}) async {
    return Map.from(_m);
  }

  @override
  Future<void> deleteAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, MacOsOptions? mOptions, WindowsOptions? wOptions, WebOptions? webOptions}) async {
    _m.clear();
  }

  @override
  Future<bool> containsKey({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, MacOsOptions? mOptions, WindowsOptions? wOptions, WebOptions? webOptions}) async {
    return _m.containsKey(key);
  }
}

void main() {
  test('save and get api key roundtrip (mocked)', () async {
    final mock = _InMemorySecureStorage();
    final store = EncryptedStore(mock);

    await store.saveApiKey('prov', 'secret123');
    final got = await store.getApiKey('prov');
    expect(got, 'secret123');
  });
}
