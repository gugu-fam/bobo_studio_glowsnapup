import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bobo_studio_glowsnapup/features/product/photo_studio_widget.dart';
import 'package:bobo_studio_glowsnapup/features/product/photo_studio_service.dart';

class FakeService extends PhotoStudioService {
	bool convertCalled = false;
	bool saveCalled = false;

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
		await tester.pumpAndSettle();

		// Verify service calls
		expect(service.convertCalled, isTrue);
		expect(service.saveCalled, isTrue);
	});
}
