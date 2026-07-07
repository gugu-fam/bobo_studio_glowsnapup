import 'package:flutter_test/flutter_test.dart';
import 'package:bobo_studio_glowsnapup/core/logger.dart';

void main() {
  test('AppLogger.info prints without throwing', () {
    expect(() => AppLogger.info('test', 'hello'), returnsNormally);
  });

  test('AppLogger.error prints without throwing', () {
    expect(() => AppLogger.error('test', Exception('e')), returnsNormally);
  });
}
