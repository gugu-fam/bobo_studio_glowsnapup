import 'dart:io';
import 'package:flutter/material.dart';
import '../../ui/photo_editor.dart';
import 'photo_studio_service.dart';

class PhotoStudioWidget extends StatelessWidget {
	final PhotoStudioService service;
	final File? initialImage;

	const PhotoStudioWidget({Key? key, required this.service, this.initialImage}) : super(key: key);

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Photo Studio')),
			body: SafeArea(
				child: PhotoEditor(
					initialImage: initialImage,
					onSave: (File edited) async {
						final converted = await service.convertImage(edited, quality: 80);
						final saved = await service.saveEditedImage(converted);
						final message = saved ? 'Saved' : 'Save failed';
						ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
					},
				),
			),
		);
	}
}
