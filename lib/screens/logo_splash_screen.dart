// logo screen

import 'package:flutter/material.dart';
import 'entrance_screen.dart';

class LogoSplashScreen extends StatelessWidget {
  const LogoSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAA520), // Golden background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your app logo in a styled circle
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFB22222),
                    width: 5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset(
                    'assets/images/Logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // App title
              const Text(
                '🎻 Violin Tuner 🎻',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB22222),
                  fontFamily: 'Georgia',
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                'Knight\'s Practice Quest',
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFF8B0000),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 80),
              
              // Start button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const EntranceScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB22222),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.play_arrow, size: 40),
                    SizedBox(width: 10),
                    Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}