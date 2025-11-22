import 'package:flutter/material.dart';
import 'violin_tuner.dart';
import 'knights_practice_timer.dart';

class TuningQuestionScreen extends StatelessWidget {
  const TuningQuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double w = size.width;
    final double h = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(w * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Custom Image/Fallback Section ---
                Container(
                  constraints: BoxConstraints.loose(Size(w * 0.7, h * 0.4)), // Limits max size
                  child: Image.asset(
                    'assets/images/help_tuning.png', // Your Image Path
                    fit: BoxFit.contain,
                    // Fallback Option (errorBuilder)
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback Text if image fails to load
                      return Text(
                        'Do you need help tuning?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: w * 0.07,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB22222),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: h * 0.05), // Adjusted spacing

                // YES button (Logic remains unchanged)
                SizedBox(
                  width: w * 0.7,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViolinTuner(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF228B22),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: h * 0.025),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 8,
                    ),
                    child: Text(
                      'Yes',
                      style: TextStyle(
                        fontSize: w * 0.07,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.025),

                // NO button (Logic remains unchanged)
                SizedBox(
                  width: w * 0.7,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const KnightsPracticeTimer(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: h * 0.025),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 8,
                    ),
                    child: Text(
                      'No',
                      style: TextStyle(
                        fontSize: w * 0.07,
                        fontWeight: FontWeight.bold,
                      ),
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