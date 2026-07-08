import 'dart:io';
import 'package:flutter/material.dart';
import '../../ui/photo_editor.dart';
import 'photo_studio_service.dart';

class PhotoStudioWidget extends StatefulWidget {
	final PhotoStudioService service;
	final File? initialImage;

	const PhotoStudioWidget({Key? key, required this.service, this.initialImage}) : super(key: key);

	@override
	State<PhotoStudioWidget> createState() => _PhotoStudioWidgetState();
}

class _PhotoStudioWidgetState extends State<PhotoStudioWidget> {
	bool _uploading = false;

	Future<void> _handleSave(File edited) async {
		setState(() => _uploading = true);
		try {
			final converted = await widget.service.convertImage(edited, quality: 80);
			final saved = await widget.service.saveEditedImage(converted);
			if (!saved) {
				ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save failed')));
				setState(() => _uploading = false);
				return;
			}

			// attempt upload
			try {
				final meta = UploadMeta(filename: converted.path.split(Platform.pathSeparator).last);
				final result = await widget.service.uploadPhoto(converted, meta);
				ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploaded: ${result.id}')));
			} catch (e) {
				// show error dialog with retry option
				await showDialog<void>(context: context, builder: (ctx) {
					return AlertDialog(
						title: const Text('Upload failed'),
						content: Text(e.toString()),
						actions: [
							TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
						],
					);
				});
			}
		} finally {
			setState(() => _uploading = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Photo Studio')),
			body: SafeArea(
				child: Stack(
					children: [
						PhotoEditor(
							initialImage: widget.initialImage,
							onSave: (File edited) async {
								await _handleSave(edited);
							},
						),
						if (_uploading)
							const Positioned.fill(
								child: ColoredBox(
									color: Color.fromRGBO(0, 0, 0, 0.3),
									child: Center(child: CircularProgressIndicator()),
								),
							),
					],
				),
			),
		);
	}
}
