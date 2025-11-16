import 'package:flutter/material.dart';
import 'screens/entrance_screen.dart';

void main() {
  runApp(const KnightsPracticeApp());
}

class KnightsPracticeApp extends StatelessWidget {
  const KnightsPracticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knight\'s Practice',
      theme: ThemeData(fontFamily: 'Georgia'),
      home: const EntranceScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

