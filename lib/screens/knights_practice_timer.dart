import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/bow_animation.dart';
import '../widgets/sword_icon.dart';
import 'treasure_chest_page.dart';

class KnightsPracticeTimer extends StatefulWidget {
  const KnightsPracticeTimer({super.key});

  @override
  State<KnightsPracticeTimer> createState() => _KnightsPracticeTimerState();
}

class _KnightsPracticeTimerState extends State<KnightsPracticeTimer> {
  int _seconds = 0;
  bool _isRunning = false;
  Timer? _timer;

  bool _token1Full = false;
  bool _token2Full = false;
  bool _token3Full = false;

  void _startPause() {
    setState(() {
      _isRunning = !_isRunning;
    });

    if (_isRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;

          if (_seconds == 5 * 60) _token1Full = true;
          if (_seconds == 10 * 60) _token2Full = true;
          if (_seconds == 15 * 60) _token3Full = true;
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  void _reset() {
    setState(() {
      _isRunning = false;
      _seconds = 0;
      _token1Full = false;
      _token2Full = false;
      _token3Full = false;
    });
    _timer?.cancel();
  }

  void _showFinishedDialog() {
    // Stop the timer if it's running
    if (_isRunning) {
      setState(() {
        _isRunning = false;
      });
      _timer?.cancel();
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFDAA520),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF8B4513), width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Treasure chest image
                Image.asset(
                  'images/treasure_chest.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                
                // Text
                const Text(
                  'Collect treasures!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB22222),
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 24),
                
                // Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TreasureChestPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 32,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go to Treasure Chest',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime() {
    int mins = _seconds ~/ 60;
    int secs = _seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  String _formatMinutes() {
    int mins = _seconds ~/ 60;
    return '$mins ${mins == 1 ? 'minute' : 'minutes'}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SwordIcon(size: 60),
                    SizedBox(width: 20),
                    Text(
                      'Knight\'s Practice',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB22222),
                      ),
                    ),
                    SizedBox(width: 20),
                    SwordIcon(size: 60),
                  ],
                ),
              ),

              // 🎻 Violin + Bow Stack
              SizedBox(
                height: 240,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Violin
                    Transform.rotate(
                      angle: -0.51,
                      child: Image.asset(
                        'assets/images/violin.png',
                        width: 250,
                        height: 460,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Bow (on top) - FLIPPED
                    if (_isRunning)
                      Positioned(
                        top: 10,
                        child: Transform.rotate(
                          angle: -15,
                          child: Transform.flip(
                            flipY: true,
                            child: BowAnimation(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 🏆 Tokens
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildToken(_token1Full),
                    const SizedBox(width: 20),
                    _buildToken(_token2Full),
                    const SizedBox(width: 20),
                    _buildToken(_token3Full),
                  ],
                ),
              ),

              // Timer Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFe8e8e8),
                      Color(0xFFc0c0c0),
                      Color(0xFFa8a8a8),
                      Color(0xFF909090),
                      Color(0xFFa8a8a8),
                      Color(0xFFc0c0c0),
                      Color(0xFFe8e8e8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Color(0xFF707070), width: 2),
                ),
                child: Text(
                  _formatTime(),
                  style: const TextStyle(
                    fontSize: 48,
                    color: Color(0xFF2a2a2a),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _formatMinutes(),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF8B0000),
                  ),
                ),
              ),

              // ▶ / ⏸ Button and Reset Button
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _startPause,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8C00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                          side: const BorderSide(
                              color: Color.fromARGB(99, 168, 158, 145), width: 3),
                        ),
                        elevation: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_isRunning ? '⏸' : '▶',
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            _isRunning ? 'Pause' : 'Start',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _reset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB22222),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                          side: const BorderSide(
                              color: Color.fromARGB(99, 168, 158, 145), width: 3),
                        ),
                        elevation: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('↺', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Stop - Finished button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: ElevatedButton(
                  onPressed: _showFinishedDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                      side: const BorderSide(
                          color: Color.fromARGB(99, 168, 158, 145), width: 3),
                    ),
                    elevation: 6,
                  ),
                  child: const Text(
                    'Stop - Finished',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToken(bool isFull) {
    return Opacity(
      opacity: isFull ? 1.0 : 0.3,
      child: Text(
        '🏆',
        style: TextStyle(
          fontSize: 40,
          shadows: isFull
              ? [
                  Shadow(
                    color: const Color(0xFFFFD700).withOpacity(0.8),
                    blurRadius: 10,
                  ),
                  const Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ]
              : [
                  const Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
        ),
      ),
    );
  }
}