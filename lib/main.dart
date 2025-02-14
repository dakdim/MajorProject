import 'package:flutter/material.dart';
// import 'view/home.dart'; // Import home.dart
import 'view/splash.dart';
// import 'dart:ui';

void main() {
  runApp(const MyApp()); // Root widget
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'hey,you there?',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // Use myapp from home.dart as the home screen
    );
  }
}
