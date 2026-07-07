import 'package:flutter_test/flutter_test.dart';
import 'package:bobo_studio_glowsnapup/features/product/photo_studio.dart';

void main() {
  test('processImage returns transformed image and metadata', () async {
    final svc = PhotoStudioService();
    final input = <int>[1, 2, 3, 4];
    final result = await svc.processImage(Uint8List.fromList(input));
    expect(result, isNotNull);
    expect(result.image, isNotNull);
    expect(result.metadata.containsKey('timestamp'), true);
  });

  test('generatePreview returns image bytes', () async {
    final svc = PhotoStudioService();
    final input = <int>[5, 6, 7, 8];
    final preview = await svc.generatePreview(Uint8List.fromList(input));
    expect(preview, isNotNull);
    expect(preview, Uint8List.fromList(input));
  });
}
