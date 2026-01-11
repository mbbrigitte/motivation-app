import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_testapplication/services/storage_service.dart';
import '../goal_reached.dart';

class OpenGatesChallenge extends StatefulWidget {
  final bool isReplay;
  
  const OpenGatesChallenge({super.key, this.isReplay = false});

  @override
  State<OpenGatesChallenge> createState() => _OpenGatesChallengeState();
}

class _OpenGatesChallengeState extends State<OpenGatesChallenge> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentTokens = 0;
  
  // Challenge state
  bool _isListening = false;
  bool _isRecording = false;
  bool _hasPlayedAudio = false;
  bool _showResult = false;
  bool _success = false;
  bool _showQuiz = false;
  int _currentLevel = 1;
  
  // Tap recording
  List<int> _userTapTimestamps = [];
  List<int> _userTapIntervals = [];
  
  // Expected rhythm patterns (intervals in milliseconds)
  // Knockrythm1: 11 knocks
  // Starting at 9008ms, shifted to 0: [0, 358, 1044, 1402, 1745, 2447, 2805, 3163, 3865, 4208, 4582]
  // Intervals: [358, 686, 358, 343, 702, 358, 358, 702, 343, 374]
  // Rounded to nearest 50ms for tolerance: [350, 700, 350, 350, 700, 350, 350, 700, 350, 350]
  
  // Knockrythm2: 8 knocks
  // Starting at 5302ms, shifted to 0: [0, 832, 1145, 1798, 2403, 3008, 3336, 3630]
  // Intervals: [832, 313, 653, 605, 605, 328, 294]
  // Rounded: [850, 300, 650, 600, 600, 350, 300]
  
  final Map<int, List<int>> _expectedIntervals = {
    1: [350, 700, 350, 350, 700, 350, 350, 700, 350, 350], // 10 intervals = 11 knocks
    2: [850, 300, 650, 600, 600, 350, 300], // 7 intervals = 8 knocks
  };
  
  // Tolerance (±200ms is more forgiving for complex rhythms)
  final int _tolerance = 200;
  
  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showTapFeedback = false;

  @override
  void initState() {
    super.initState();
    _loadTokens();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    
    if (!widget.isReplay) {
      StorageService.unlockChallenge('opengates_challenge');
    }
  }

  Future<void> _loadTokens() async {
    int tokens = await StorageService.loadTokens();
    setState(() {
      _currentTokens = tokens;
    });
  }

  Future<void> _playRhythmAudio() async {
    setState(() {
      _isListening = true;
      _hasPlayedAudio = true;
      _showResult = false;
    });

    try {
      String audioFile = _currentLevel == 1 ? 'Knockrythm1.m4a' : 'Knockrythm2.m4a';
      await _audioPlayer.play(AssetSource('audio/$audioFile'));
      
      // Wait for audio to finish
      await Future.delayed(const Duration(seconds: 15));
      
      setState(() {
        _isListening = false;
      });
    } catch (e) {
      print('Error playing audio: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _userTapTimestamps.clear();
      _userTapIntervals.clear();
      _showResult = false;
    });
  }

  void _onTap() {
    if (!_isRecording) return;

    int now = DateTime.now().millisecondsSinceEpoch;
    
    setState(() {
      _userTapTimestamps.add(now);
      _showTapFeedback = true;
    });

    _pulseController.forward().then((_) => _pulseController.reverse());
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _showTapFeedback = false;
        });
      }
    });

    // Auto-check if we have enough taps
    int expectedTaps = (_expectedIntervals[_currentLevel]?.length ?? 0) + 1;
    if (_userTapTimestamps.length >= expectedTaps) {
      _stopRecording();
    }
  }

  void _stopRecording() {
    if (!_isRecording || _userTapTimestamps.length < 2) return;

    // Calculate intervals between taps
    for (int i = 1; i < _userTapTimestamps.length; i++) {
      _userTapIntervals.add(_userTapTimestamps[i] - _userTapTimestamps[i - 1]);
    }

    setState(() {
      _isRecording = false;
    });

    _checkRhythm();
  }

  void _checkRhythm() {
    List<int> expected = _expectedIntervals[_currentLevel] ?? [];
    
    // Check if user provided the right number of taps
    if (_userTapIntervals.length != expected.length) {
      setState(() {
        _success = false;
        _showResult = true;
      });
      return;
    }

    // Check if intervals match within tolerance
    bool allMatch = true;
    for (int i = 0; i < expected.length; i++) {
      int difference = (_userTapIntervals[i] - expected[i]).abs();
      if (difference > _tolerance) {
        allMatch = false;
        break;
      }
    }

    setState(() {
      _success = allMatch;
      _showResult = true;
    });

    if (_success) {
      _showQuizDialog();
    }
  }

  void _showQuizDialog() {
    final quizData = _currentLevel == 1
        ? {
            'question': 'What did this knocking rhythm remind you of?',
            'options': [
              'A: Song of the Wind',
              'B: Go Tell Aunt Rhody',
              'C: O Come, Little Children'
            ],
            'correct': 2, // Index of correct answer (C)
          }
        : {
            'question': 'What did this knocking rhythm remind you of?',
            'options': ['A: Long, Long Ago', 'B: May Song', 'C: Winter Serenade'],
            'correct': 1, // Index of correct answer (B: May Song)
          };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.green[700]!,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white, width: 3),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              quizData['question'] as String,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...(quizData['options'] as List<String>).asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleQuizAnswer(entry.key == quizData['correct']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[900],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _handleQuizAnswer(bool isCorrect) async {
    if (isCorrect) {
      if (_currentLevel == 1) {
        // First level complete, move to level 2
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
              content: const Text(
                'Correct! But the door needs a secret knock...\n\nTry the second pattern!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );

          await Future.delayed(const Duration(seconds: 3));

          if (mounted) {
            Navigator.of(context).pop();
            setState(() {
              _currentLevel = 2;
              _hasPlayedAudio = false;
              _showResult = false;
            });
          }
        }
      } else {
        // Both levels complete!
        if (!widget.isReplay) {
          await _addToken();
        }

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
                widget.isReplay
                    ? 'Congratulations, you are granted access to the castle!\n\nThe doors open!'
                    : 'Congratulations, you are granted access to the castle!\n\nThe doors open!\n\nYou earned one token!\nYou now have a total of $_currentTokens tokens!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );

          await Future.delayed(const Duration(seconds: 3));

          if (mounted) {
            Navigator.of(context).pop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => GoalReached()),
            );
          }
        }
      }
    } else {
      // Wrong answer - show correct answer and continue
      final correctAnswer = _currentLevel == 1 
          ? 'C: O Come, Little Children' 
          : 'B: May Song';
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.orange[700]!,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white, width: 3),
            ),
            content: Text(
              'The correct answer was:\n$correctAnswer\n\nLet\'s continue!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 3));

        if (mounted) {
          Navigator.of(context).pop();
          
          // Continue to next level or finish
          if (_currentLevel == 1) {
            setState(() {
              _currentLevel = 2;
              _hasPlayedAudio = false;
              _showResult = false;
            });
          } else {
            // Both levels complete!
            if (!widget.isReplay) {
              await _addToken();
            }

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
                    widget.isReplay
                        ? 'Congratulations, you are granted access to the castle!\n\nThe doors open!'
                        : 'Congratulations, you are granted access to the castle!\n\nThe doors open!\n\nYou earned one token!\nYou now have a total of $_currentTokens tokens!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );

              await Future.delayed(const Duration(seconds: 3));

              if (mounted) {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => GoalReached()),
                );
              }
            }
          }
        }
      }
    }
  }

  Future<void> _addToken() async {
    int currentTokens = await StorageService.loadTokens();
    await StorageService.saveTokens(currentTokens + 1);

    int totalTokens = await StorageService.loadTotalTokens();
    await StorageService.saveTotalTokens(totalTokens + 1);

    int updatedTokens = await StorageService.loadTokens();

    setState(() {
      _currentTokens = updatedTokens;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: Text('The Castle Door - Level $_currentLevel'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.02),

              // Instruction text
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.red[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  _currentLevel == 1
                      ? 'You reached the castle, but the doors are closed.\n\nKnock in the right rhythm so that someone lets you in!'
                      : 'Almost there! Try the secret knock pattern!',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: screenHeight * 0.01),

              // Door with overlaid knock button
              SizedBox(
                width: screenWidth * 0.7,
                height: screenWidth * 0.7 * 1.5,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Door image with blurred edges
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDAA520).withOpacity(0.8),
                            blurRadius: 30,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Opacity(
                          opacity: _isRecording ? 0.7 : 1.0,
                          child: Image.asset(
                            'assets/images/doors.webp',
                            width: screenWidth * 0.7,
                            height: screenWidth * 0.7 * 1.5,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // Knock button overlay (only show when recording)
                    if (_isRecording)
                      GestureDetector(
                        onTap: _onTap,
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: screenWidth * 0.48, // 20% smaller (0.6 * 0.8)
                            height: screenWidth * 0.48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _showTapFeedback 
                                  ? Colors.red[700] 
                                  : Colors.red[900],
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    size: screenWidth * 0.12,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Text(
                                    'KNOCK\nHERE',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.05,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Listen button
              if (!_hasPlayedAudio || _isListening)
                ElevatedButton.icon(
                  onPressed: _isListening ? null : _playRhythmAudio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.08,
                      vertical: screenHeight * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    _isListening ? Icons.hearing : Icons.volume_up,
                    size: screenWidth * 0.08,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isListening ? 'Listening...' : 'Listen to the Rhythm',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Ready to Knock button
              if (_hasPlayedAudio && !_isListening && !_isRecording && !_showResult)
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.02),
                  child: ElevatedButton(
                    onPressed: _startRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.08,
                        vertical: screenHeight * 0.02,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Ready to Knock!',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Knock counter
              if (_isRecording)
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.02),
                  child: Text(
                    'Knocks: ${_userTapTimestamps.length}/${(_expectedIntervals[_currentLevel]?.length ?? 0) + 1}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[900],
                    ),
                  ),
                ),

              // Error message and retry buttons
              if (_hasPlayedAudio && !_isListening)
                Column(
                  children: [

                    if (_showResult && !_success)
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.02),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              decoration: BoxDecoration(
                                color: Colors.red[700],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Text(
                                'Not quite right...\nWould you like to try again?',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    // Continue as if correct
                                    setState(() {
                                      _success = true;
                                    });
                                    _showQuizDialog();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[700],
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.08,
                                      vertical: screenHeight * 0.015,
                                    ),
                                  ),
                                  child: const Text(
                                    'No',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.04),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _showResult = false;
                                      _hasPlayedAudio = false;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[700],
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.08,
                                      vertical: screenHeight * 0.015,
                                    ),
                                  ),
                                  child: const Text(
                                    'Yes',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}