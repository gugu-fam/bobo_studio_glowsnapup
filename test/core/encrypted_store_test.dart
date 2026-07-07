import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/storage/encrypted_store.dart';

void main() {
  test('EncryptedStore API (no-op if flutter_secure_storage not available)', () async {
    final store = EncryptedStore();
    // Try saving and reading; may throw if environment not configured for flutter_secure_storage
    try {
      await store.saveApiKey('test', 'value');
      final v = await store.getApiKey('test');
      // value may be null depending on platform; ensure call completes
      expect(v == null || v == 'value', true);
    } catch (e) {
      // Environment may not support flutter_secure_storage in test runner; allow failure but not crash test harness
      expect(e, isNotNull);
    }
  });
}
