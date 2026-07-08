// lib/ui/photo_editor.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

typedef OnImageEdited = void Function(File editedImage);

class PhotoEditor extends StatefulWidget {
  final File? initialImage;
  final OnImageEdited? onSave;

  const PhotoEditor({Key? key, this.initialImage, this.onSave}) : super(key: key);

  @override
  State<PhotoEditor> createState() => _PhotoEditorState();
}

class _PhotoEditorState extends State<PhotoEditor> {
  File? _image;
  double _brightness = 0.0;
  double _rotation = 0.0;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _image = widget.initialImage;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _image = File(picked.path));
      }
    } catch (e) {
      // swallow for testability; in real app surface an error
    }
  }

  void _save() {
    if (_image != null && widget.onSave != null) {
      widget.onSave!(_image!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: _image == null
                ? const Text('No image selected')
                : Transform.rotate(
                    angle: _rotation,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color.fromRGBO(255, 255, 255, _brightness.abs()),
                        BlendMode.modulate,
                      ),
                      child: Image.file(_image!),
                    ),
                  ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              key: const Key('pick_button'),
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick'),
            ),
            ElevatedButton.icon(
              key: const Key('save_button'),
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const Text('Brightness'),
              Slider(
                key: const Key('brightness_slider'),
                value: _brightness,
                min: -1.0,
                max: 1.0,
                onChanged: (v) => setState(() => _brightness = v),
              ),
              const Text('Rotation'),
              Slider(
                key: const Key('rotation_slider'),
                value: _rotation,
                min: -3.14,
                max: 3.14,
                onChanged: (v) => setState(() => _rotation = v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
// AUTO-GEN skeleton
