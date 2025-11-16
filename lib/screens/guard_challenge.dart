import 'package:flutter/material.dart';

class GuardChallenge extends StatelessWidget {
  const GuardChallenge({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard Challenge'),
        backgroundColor: Colors.red[900],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You\'ve reached the Guard!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Return to Treasure Chest'),
            ),
          ],
        ),
      ),
    );
  }
}