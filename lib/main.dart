import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'theme.dart';
import 'ui/shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const InkaApp());
}

class InkaApp extends StatelessWidget {
  const InkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'INKASTREAM',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const Shell(),
    );
  }
}
