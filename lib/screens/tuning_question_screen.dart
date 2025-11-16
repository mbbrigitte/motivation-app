import 'package:flutter/material.dart';
import 'violin_tuner.dart';
import 'knights_practice_timer.dart';
import '../widgets/sword_icon.dart';

class TuningQuestionScreen extends StatelessWidget {
  const TuningQuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title with swords
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SwordIcon(size: 50),
                    SizedBox(width: 20),
                    Flexible(
                      child: Text(
                        'Tune Your Violin?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB22222),
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    SwordIcon(size: 50),
                  ],
                ),
                
                const SizedBox(height: 60),
                
                // Violin image (optional - if you have one)
                const Text(
                  '🎻',
                  style: TextStyle(fontSize: 120),
                ),
                
                const SizedBox(height: 40),
                
                // Question text
                const Text(
                  'Would you like help\ntuning your violin first?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B0000),
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // YES button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViolinTuner(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF228B22), // Forest green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 60,
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
                    '✓ Yes, help me tune',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // NO button
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
                    backgroundColor: const Color(0xFFFF8C00), // Dark orange
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 60,
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
                    '✗ No, start practice',
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
      ),
    );
  }
}