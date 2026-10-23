import 'package:flutter/material.dart';
import 'theme.dart';

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
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              'INKASTREAM',
              style: TextStyle(
                color: AppColors.red,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
