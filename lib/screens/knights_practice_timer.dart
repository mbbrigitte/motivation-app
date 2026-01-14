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
        final size = MediaQuery.of(context).size;
        final double w = size.width;
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(w * 0.06),
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
                  'assets/images/treasure_chest.png',
                  width: w * 0.5,
                  height: w * 0.5,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      '💰',
                      style: TextStyle(fontSize: w * 0.3),
                    );
                  },
                ),
                SizedBox(height: w * 0.05),
                
                // Text
                Text(
                  'Collect treasures!',
                  style: TextStyle(
                    fontSize: w * 0.07,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB22222),
                    fontFamily: 'Georgia',
                  ),
                ),
                SizedBox(height: w * 0.06),
                
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
                    padding: EdgeInsets.symmetric(
                      vertical: w * 0.04,
                      horizontal: w * 0.08,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Go to Treasure Chest',
                    style: TextStyle(
                      fontSize: w * 0.045,
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
    final size = MediaQuery.of(context).size;
    final double w = size.width;
    final double h = size.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Back arrow at top left
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: w * 0.01, top: h * 0.005),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: const Color(0xFFB22222),
                      size: w * 0.06,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),

              // Title with swords
              Padding(
                padding: EdgeInsets.only(top: h * 0.01, bottom: h * 0.02),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SwordIcon(size: w * 0.08),
                    SizedBox(width: w * 0.03),
                    Flexible(
                      child: Text(
                        'Knight\'s Practice',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: w * 0.07,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB22222),
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    SwordIcon(size: w * 0.08),
                  ],
                ),
              ),

              // 🎻 Violin + Bow Stack - Made smaller and more responsive
              SizedBox(
                height: h * 0.18,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Violin
                    Transform.rotate(
                      angle: -0.51,
                      child: Image.asset(
                        'assets/images/violin.png',
                        width: w * 0.45,
                        height: h * 0.4,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Bow (on top) - FLIPPED
                    if (_isRunning)
                      Positioned(
                        top: h * 0.01,
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

              SizedBox(height: h * 0.015),

              // 🏆 Tokens - Made smaller and more compact
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildToken(_token1Full, w),
                  SizedBox(width: w * 0.03),
                  _buildToken(_token2Full, w),
                  SizedBox(width: w * 0.03),
                  _buildToken(_token3Full, w),
                ],
              ),

              SizedBox(height: h * 0.02),

              // Timer Display - Made more compact
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.08,
                  vertical: h * 0.015,
                ),
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
                  border: Border.all(color: const Color(0xFF707070), width: 2),
                ),
                child: Text(
                  _formatTime(),
                  style: TextStyle(
                    fontSize: w * 0.1,
                    color: const Color(0xFF2a2a2a),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: h * 0.008),

              // Minutes text
              Text(
                _formatMinutes(),
                style: TextStyle(
                  fontSize: w * 0.045,
                  color: const Color(0xFF8B0000),
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: h * 0.03),

              // ▶ / ⏸ Button and Reset Button - More compact
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _startPause,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.06,
                        vertical: h * 0.015,
                      ),
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
                            style: TextStyle(fontSize: w * 0.045)),
                        SizedBox(width: w * 0.02),
                        Text(
                          _isRunning ? 'Pause' : 'Start',
                          style: TextStyle(
                            fontSize: w * 0.045,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: w * 0.04),
                  ElevatedButton(
                    onPressed: _reset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB22222),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.06,
                        vertical: h * 0.015,
                      ),
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
                        Text('↺', style: TextStyle(fontSize: w * 0.045)),
                        SizedBox(width: w * 0.02),
                        Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: w * 0.045,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: h * 0.02),

              // Stop - Finished button
              ElevatedButton(
                onPressed: _showFinishedDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.1,
                    vertical: h * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    side: const BorderSide(
                        color: Color.fromARGB(99, 168, 158, 145), width: 3),
                  ),
                  elevation: 6,
                ),
                child: Text(
                  'Stop - Finished',
                  style: TextStyle(
                    fontSize: w * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: h * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToken(bool isFull, double w) {
    return Opacity(
      opacity: isFull ? 1.0 : 0.3,
      child: Text(
        '🏆',
        style: TextStyle(
          fontSize: w * 0.08,
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