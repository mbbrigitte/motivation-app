import 'package:flutter/material.dart';

class WishingWellChallenge extends StatelessWidget {
  const WishingWellChallenge({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishing Well Challenge'),
        backgroundColor: Colors.red[900],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You\'ve reached the Wishing Well!',
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