// Path: lib/features/product/viewmodel/photo_studio_viewmodel.dart
// AUTO-GEN implementation

import 'dart:async';
import 'dart:typed_data';
import '../photo_studio.dart';

enum PhotoStudioState { idle, processing, success, failure }

class PhotoStudioViewModel {
  final PhotoStudioService _service;
  PhotoStudioState _state = PhotoStudioState.idle;
  PhotoStudioState get state => _state;

  final StreamController<PhotoStudioState> _stateController = StreamController.broadcast();
  Stream<PhotoStudioState> get stateStream => _stateController.stream;

  PhotoStudioViewModel(this._service);

  Future<void> startProcessing(Uint8List image, {Map<String, dynamic>? options}) async {
    _updateState(PhotoStudioState.processing);
    try {
      await _service.processImage(image, options: options);
      // 結果を必要に応じて保存または通知する
      _updateState(PhotoStudioState.success);
    } catch (e) {
      _updateState(PhotoStudioState.failure);
    }
  }

  StreamSubscription<PhotoStudioState> observeState(void Function(PhotoStudioState) onChange) {
    return stateStream.listen(onChange);
  }

  void _updateState(PhotoStudioState s) {
    _state = s;
    _stateController.add(s);
  }

  void dispose() {
    _stateController.close();
  }
}

