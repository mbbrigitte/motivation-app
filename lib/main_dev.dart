import 'package:flutter/material.dart';
import 'screens/challenges/animal_challenge.dart';
import 'services/storage_service.dart';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Optional: Reset storage for testing
  // await _resetStorageForTesting();
  
  runApp(const MyDevApp());
}

// Uncomment this function if you want to reset storage each time you run
Future<void> _resetStorageForTesting() async {
  await StorageService.saveTokens(0);
  await StorageService.saveTotalTokens(0);
  await StorageService.saveLastHandledMilestone(0);
  await StorageService.clearKnightPosition();
}

class MyDevApp extends StatelessWidget {
  const MyDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dev - Animal Challenge',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      // Start directly with the Animal Challenge
      home: const AnimalChallenge(isReplay: false),
    );
  }
}