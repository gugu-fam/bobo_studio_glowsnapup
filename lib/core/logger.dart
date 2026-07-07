// Path: lib/core/logger.dart
// AUTO-GEN implementation (minimal)

import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String tag, String message) {
    final ts = DateTime.now().toIso8601String();
    // Lightweight console logging for now
    // In production switch to file + audit forwarding
    debugPrint('[INFO] $ts $tag: $message');
  }

  static void error(String tag, Object error) {
    final ts = DateTime.now().toIso8601String();
    debugPrint('[ERROR] $ts $tag: $error');
    // Hook for audit forwarding can be added later
  }
}

