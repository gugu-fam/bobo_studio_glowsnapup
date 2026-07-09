import 'package:flutter/material.dart';

void main() {
  runApp(const _PlaceholderApp());
}

class _PlaceholderApp extends StatelessWidget {
  const _PlaceholderApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Placeholder App')),
      ),
    );
  }
}
