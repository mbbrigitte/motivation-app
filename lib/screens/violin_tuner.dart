import 'package:flutter/material.dart';
import 'knights_practice_timer.dart';
import '../widgets/sword_icon.dart';

class ViolinTuner extends StatelessWidget {
  const ViolinTuner({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: const Text(
          '🎻 Violin Tuner 🎻',
          style: TextStyle(fontSize: 26),
        ),
        backgroundColor: const Color(0xFFB22222),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SwordIcon(size: 40),
                  SizedBox(width: 16),
                  Text(
                    'Tune Your Violin',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB22222),
                      fontFamily: 'Georgia',
                    ),
                  ),
                  SizedBox(width: 16),
                  SwordIcon(size: 40),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Placeholder text
              const Text(
                'Tuning features coming soon!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  color: Color(0xFF8B0000),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Violin emoji
              const Text(
                '🎻',
                style: TextStyle(fontSize: 100),
              ),
              
              const SizedBox(height: 40),
              
              // String names for reference
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.brown[700],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFF8B4513),
                    width: 3,
                  ),
                ),
                child: Column(
                  children: const [
                    Text(
                      'Violin Strings:',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'G - D - A - E',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        letterSpacing: 8,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Continue to practice button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KnightsPracticeTimer(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF228B22),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 40,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    side: const BorderSide(
                      color: Color.fromARGB(99, 168, 158, 145),
                      width: 3,
                    ),
                  ),
                  elevation: 6,
                ),
                child: const Text(
                  'Continue to Practice →',
                  style: TextStyle(
                    fontSize: 22,
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