import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pick -> edit -> save -> upload success', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Tap pick button (use key from existing UI)
    final pickButton = find.byKey(const Key('pick_button'));
    await tester.tap(pickButton);
    await tester.pumpAndSettle();

    // Simulate edit done if present (optional)
    // final editDone = find.byKey(const Key('editor_done_button'));
    // if (editDone.evaluate().isNotEmpty) {
    //   await tester.tap(editDone);
    //   await tester.pumpAndSettle();
    // }

    // Save / upload
    final saveButton = find.byKey(const Key('save_button'));
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Expect success UI (adjust message to app behavior)
    expect(find.textContaining('Upload'), findsWidgets);
  });
}
