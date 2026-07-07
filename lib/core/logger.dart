// Path: lib/core/logger.dart
// AUTO-GEN implementation (minimal)

class AppLogger {
  static void info(String tag, String message) {
    final ts = DateTime.now().toIso8601String();
    // Lightweight console logging for now
    // In production switch to file + audit forwarding
    print('[INFO] $ts $tag: $message');
  }

  static void error(String tag, Object error) {
    final ts = DateTime.now().toIso8601String();
    print('[ERROR] $ts $tag: $error');
    // Hook for audit forwarding can be added later
  }
}

