import 'package:flutter/material.dart';
import 'dart:async';
import '../services/storage_service.dart';
import 'practice_finished.dart';

class InstrumentChallenge extends StatefulWidget {
  const InstrumentChallenge({super.key});

  @override
  State<InstrumentChallenge> createState() => _InstrumentChallengeState();
}

class _InstrumentChallengeState extends State<InstrumentChallenge> {
  bool _buttonPressed = false;
  int _currentPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    int points = await StorageService.loadPoints();
    setState(() {
      _currentPoints = points;
    });
  }

  Future<void> _onCorrectAnswer() async {
    if (_buttonPressed) return;

    setState(() {
      _buttonPressed = true;
    });

    // Add point + token
    await _addPointAndToken();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.green[700]!,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white, width: 3),
          ),
          content: Text(
            'Well done! You receive one extra token!\nYou now have a total of $_currentPoints points!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 4));

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PracticeFinished()),
        );
      }
    }
  }

  Future<void> _onWrongAnswer() async {
    if (_buttonPressed) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.orange[700]!,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white, width: 3),
          ),
          content: const Text(
            'Almost, try again!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _addPointAndToken() async {
    int currentTokens = await StorageService.loadTokens();
    await StorageService.saveTokens(currentTokens + 1);

    int totalTokens = await StorageService.loadTotalTokens();
    await StorageService.saveTotalTokens(totalTokens + 1);

    await StorageService.addPoints(1);
    int updatedPoints = await StorageService.loadPoints();

    setState(() {
      _currentPoints = updatedPoints;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: const Text('The Instrument Challenge'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Text(
                'The Wagon Master needs help!\nPoint to the largest instrument,\nthe Double Bass!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB22222),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Instrument image with tap detection
              GestureDetector(
                onTapDown: (details) {
                  if (_buttonPressed) return;
                  
                  // Get the tap position relative to the image
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(details.globalPosition);
                  
                  // Calculate image bounds (adjust these based on your actual image layout)
                  final imageWidth = MediaQuery.of(context).size.width - 48;
                  final imageHeight = imageWidth * 0.75; // Adjust ratio based on your image
                  
                  // Define tap regions for each instrument
                  // These are approximate - adjust based on your actual image
                  // Assuming Double Bass is on the right side of the image
                  final doubleBassRegion = Rect.fromLTWH(
                    imageWidth * 0.65, // Right 35% of image
                    0,
                    imageWidth * 0.35,
                    imageHeight,
                  );
                  
                  if (doubleBassRegion.contains(Offset(
                    localPosition.dx - 24,
                    localPosition.dy - 180, // Adjust based on layout
                  ))) {
                    _onCorrectAnswer();
                  } else {
                    _onWrongAnswer();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/Instrument.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              if (!_buttonPressed)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFB22222),
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    'Tap on the Double Bass in the picture above!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB22222),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}