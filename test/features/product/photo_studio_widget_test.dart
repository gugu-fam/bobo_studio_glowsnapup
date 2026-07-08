import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bobo_studio_glowsnapup/features/product/photo_studio_widget.dart';
import 'package:bobo_studio_glowsnapup/features/product/photo_studio_service.dart';

class FakeService extends PhotoStudioService {
	bool convertCalled = false;
	bool saveCalled = false;
	bool uploadCalled = false;
	bool uploadShouldThrow = false;

	@override
	Future<File> convertImage(File input, {int quality = 80}) async {
		convertCalled = true;
		return input;
	}

	@override
	Future<bool> saveEditedImage(File edited) async {
		saveCalled = true;
		return true;
	}

	@override
	Future<UploadResult> uploadPhoto(File file, UploadMeta meta, {String? bearerToken}) async {
		uploadCalled = true;
		if (uploadShouldThrow) throw Exception('mock upload failure');
		return UploadResult(id: 'mock', url: 'https://example/mock.jpg');
	}
}

void main() {
	testWidgets('save flow calls service convert and save', (WidgetTester tester) async {
		final service = FakeService();

		// Prepare a fake file to act as initial image
		final dir = Directory('test_resources');
		dir.createSync(recursive: true);
		final fake = File('${dir.path}/fake.jpg');
		fake.writeAsBytesSync([0]);

		await tester.pumpWidget(MaterialApp(home: PhotoStudioWidget(service: service, initialImage: fake)));

		// Verify Save button exists
		expect(find.byKey(const Key('save_button')), findsOneWidget);

		// Tap save button to trigger the flow
		await tester.tap(find.byKey(const Key('save_button')));
		await tester.pump();
		await tester.pump(const Duration(seconds: 1));

		// Verify service calls
		expect(service.convertCalled, isTrue);
		expect(service.saveCalled, isTrue);
		expect(service.uploadCalled, isTrue);
		// SnackBar for upload success should appear
		expect(find.textContaining('Uploaded:'), findsOneWidget);
	});

	testWidgets('upload failure shows dialog', (WidgetTester tester) async {
		final service = FakeService()..uploadShouldThrow = true;

		final dir = Directory('test_resources');
		dir.createSync(recursive: true);
		final fake = File('${dir.path}/fake2.jpg');
		fake.writeAsBytesSync([0]);

		await tester.pumpWidget(MaterialApp(home: PhotoStudioWidget(service: service, initialImage: fake)));
		await tester.tap(find.byKey(const Key('save_button')));
		await tester.pump();
		await tester.pump(const Duration(seconds: 1));

		expect(service.uploadCalled, isTrue);
		expect(find.text('Upload failed'), findsOneWidget);
	});
}
