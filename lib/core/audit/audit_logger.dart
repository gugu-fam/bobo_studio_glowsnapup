// Path: lib/core/audit/audit_logger.dart
// AUTO-GEN minimal AuditLogger

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class AuditLogger {
  static final _dir = Directory('audit/logs');

  static Future<String> record(String agentId, String action, List<String> filesChanged, Map<String, dynamic> validationResults) async {
    _dir.createSync(recursive: true);
    final ts = DateTime.now().toUtc().toIso8601String();
    final entry = {
      'timestamp': ts,
      'agent_id': agentId,
      'action': action,
      'files_changed': filesChanged,
      'validation_results': validationResults
    };
    final jsonText = jsonEncode(entry);
    final hash = sha256.convert(utf8.encode(jsonText)).toString();
    final filename = '${ts.replaceAll(':','-')}_audit.json';
    final file = File('${_dir.path}/$filename');
    await file.writeAsString(jsonText);
    // Optionally write hash to sidecar file
    await File('${_dir.path}/$filename.sha256').writeAsString(hash);
    return file.path;
  }
}

