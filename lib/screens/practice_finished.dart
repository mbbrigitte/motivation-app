import 'package:flutter/material.dart';
import 'package:flutter_testapplication/screens/quest_selection_screen.dart';

class PracticeFinished extends StatelessWidget {
  const PracticeFinished({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[800],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Fancy title
              Text(
                'Well done,\nbrave knight!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                  shadows: [
                    Shadow(
                      offset: const Offset(3, 3),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                  fontFamily: 'Georgia',
                  decoration: TextDecoration.none,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // "Practice more" button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const QuestSelectionScreen())
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  '⚔️ I want to practice more!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // "See you later" button
              ElevatedButton(
                onPressed: () {
                  // You can either close the app or go to entrance screen
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  '👋 I enjoyed practice today!\nSee you another time!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}