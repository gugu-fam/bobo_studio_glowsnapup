import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bobo_studio_glowsnapup/features/product/photo_studio_service.dart';

void main() {
  test('uploadPhoto returns UploadResult on 201', () async {
    final mockClient = MockClient((request) async {
      return http.Response(json.encode({'id': '123', 'url': 'https://example.test/123.jpg'}), 201);
    });

    final service = PhotoStudioService(client: mockClient, endpoint: Uri.parse('https://example.test/api/v1/photos'));

    final dir = Directory('test_resources');
    dir.createSync(recursive: true);
    final fake = File('${dir.path}/upl.jpg');
    fake.writeAsBytesSync([0]);

    final result = await service.uploadPhoto(fake, UploadMeta(filename: 'upl.jpg'));
    expect(result.id, equals('123'));
    expect(result.url, contains('123.jpg'));
  });

  test('uploadPhoto throws on 400', () async {
    final mockClient = MockClient((request) async {
      return http.Response('bad', 400);
    });

    final service = PhotoStudioService(client: mockClient, endpoint: Uri.parse('https://example.test/api/v1/photos'));
    final dir = Directory('test_resources');
    dir.createSync(recursive: true);
    final fake = File('${dir.path}/upl2.jpg');
    fake.writeAsBytesSync([0]);

    expect(() async => await service.uploadPhoto(fake, UploadMeta()), throwsA(isA<HttpException>()));
  });

  test('uploadPhoto retries on 500 then succeeds', () async {
    int calls = 0;
    final mockClient = MockClient((request) async {
      calls += 1;
      if (calls == 1) return http.Response('server error', 500);
      return http.Response(json.encode({'id': 'retry', 'url': 'https://example.test/retry.jpg'}), 200);
    });

    final service = PhotoStudioService(client: mockClient, endpoint: Uri.parse('https://example.test/api/v1/photos'));
    final dir = Directory('test_resources');
    dir.createSync(recursive: true);
    final fake = File('${dir.path}/upl3.jpg');
    fake.writeAsBytesSync([0]);

    final res = await service.uploadPhoto(fake, UploadMeta());
    expect(res.id, equals('retry'));
    expect(calls, greaterThanOrEqualTo(2));
  });
}
