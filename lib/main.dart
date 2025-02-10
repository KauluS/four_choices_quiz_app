import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Four Choices Quiz',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
