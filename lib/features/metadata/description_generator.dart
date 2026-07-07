// Path: lib/features/metadata/description_generator.dart
// AUTO-GEN implementation

class DescriptionGenerator {
  // シンプルな説明文生成。将来的に LLM を呼ぶフックを入れる。
  Future<String> generateDescription(String title, Map<String, dynamic> attributes) async {
    final buffer = StringBuffer();
    buffer.writeln(title);
    if (attributes.isNotEmpty) {
      buffer.writeln('Details:');
      attributes.forEach((k, v) {
        buffer.writeln('- $k: $v');
      });
    }
    return buffer.toString().trim();
  }
}

