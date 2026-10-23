import 'package:flutter/material.dart';
import 'theme.dart';
import 'ui/shell.dart';

void main() {
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
