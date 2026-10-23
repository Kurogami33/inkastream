import 'package:flutter/material.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE11D2E),
          surface: Color(0xFF141416),
        ),
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'INKASTREAM',
            style: TextStyle(
              color: Color(0xFFE11D2E),
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }
}
