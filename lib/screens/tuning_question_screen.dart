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
                // Violin emoji
                Text(
                  '🎻',
                  style: TextStyle(fontSize: w * 0.35),
                ),
                
                SizedBox(height: h * 0.05),
                
                // Simple question
                Text(
                  'Need help tuning?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: w * 0.08,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB22222),
                  ),
                ),
                
                SizedBox(height: h * 0.08),
                
                // YES button
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
                
                // NO button
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