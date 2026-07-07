// Path: lib/features/product/view/photo_studio_view.dart
// AUTO-GEN implementation

import 'package:flutter/material.dart';
import '../viewmodel/photo_studio_viewmodel.dart';

class PhotoStudioView extends StatefulWidget {
  final PhotoStudioViewModel viewModel;
  const PhotoStudioView({super.key, required this.viewModel});

  @override
  State<PhotoStudioView> createState() => _PhotoStudioViewState();
}

class _PhotoStudioViewState extends State<PhotoStudioView> {
  late PhotoStudioViewModel vm;
  @override
  void initState() {
    super.initState();
    vm = widget.viewModel;
    vm.observeState((s) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final state = vm.state;
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Studio')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state == PhotoStudioState.idle) const Text('Ready'),
            if (state == PhotoStudioState.processing) const CircularProgressIndicator(),
            if (state == PhotoStudioState.success) const Icon(Icons.check, color: Colors.green),
            if (state == PhotoStudioState.failure) const Icon(Icons.error, color: Colors.red),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // テスト用ダミー呼び出し。実運用ではファイル選択等を行う
              },
              child: const Text('Start Processing'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }
}

