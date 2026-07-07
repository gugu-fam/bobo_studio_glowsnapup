import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/audit/audit_logger.dart' as audit_lib;
import 'dart:io';

void main() {
  test('AuditLogger.record writes file', () async {
    final path = await audit_lib.AuditLogger.record('test_agent', 'test_action', ['a.txt'], {'ok': true});
    final f = File(path);
    expect(await f.exists(), true);
    // cleanup
    await f.delete();
    final sha = File(path + '.sha256');
    if (await sha.exists()) await sha.delete();
  });
}
