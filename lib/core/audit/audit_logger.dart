// Path: lib/core/audit/audit_logger.dart
// AUTO-GEN minimal AuditLogger

import 'dart:convert';
import 'dart:io';

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
    // Use base64 of payload as simple integrity marker in test environments
    final hash = base64Encode(utf8.encode(jsonText));
    final filename = '${ts.replaceAll(':','-')}_audit.json';
    final file = File('${_dir.path}/$filename');
    await file.writeAsString(jsonText);
    // Write sidecar marker
    await File('${_dir.path}/$filename.marker').writeAsString(hash);
    return file.path;
  }
}

