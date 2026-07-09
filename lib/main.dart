import 'package:flutter/material.dart';
import 'features/product/photo_studio_service.dart';
import 'features/product/photo_studio_widget.dart';

void main() {
  final service = PhotoStudioService(enableUpload: false);
  runApp(MyApp(service: service));
}

class MyApp extends StatelessWidget {
  final PhotoStudioService service;
  MyApp({Key? key, PhotoStudioService? service}) : service = service ?? PhotoStudioService(enableUpload: false), super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Studio',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: PhotoStudioWidget(service: service),
    );
  }
}
