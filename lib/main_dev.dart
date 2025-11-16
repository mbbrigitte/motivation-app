import 'package:flutter/material.dart';
import 'screens/treasure_chest_page.dart';
import 'screens/knight_advancer.dart';
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

//Future<void> _resetStorageForTesting() async {
//  await StorageService.saveTokens(15);  // Set current tokens
//  await StorageService.saveTotalTokens(15);  // Set total ever
//  await StorageService.saveLastHandledMilestone(0);
//  await StorageService.clearKnightPosition();
//}

class MyDevApp extends StatelessWidget {
  const MyDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dev - Knight Adventure',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Start with the Treasure Chest page
      home: const TreasureChestPage(),
      // Define routes for navigation
      routes: {
        '/treasure': (context) => const TreasureChestPage(),
        '/knight': (context) => const KnightAdvancer(),
      },
    );
  }
}