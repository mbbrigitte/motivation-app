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
  int _currentLevel = 1;
  
  // Simple step tracking: 'listen1' -> 'quiz' -> 'listen2' -> 'knock'
  String _currentStep = 'listen1';
  
  bool _isPlaying = false;
  bool _isRecording = false;
  bool _showResult = false;
  bool _success = false;
  
  // Tap recording
  List<int> _userTapTimestamps = [];
  List<int> _userTapIntervals = [];

  final Map<int, List<int>> _expectedIntervals = {
    1: [350, 700, 350, 350, 700, 350, 350, 700, 350, 350],
    2: [850, 300, 650, 600, 600, 350, 300],
  };

  final int _tolerance = 200;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showTapFeedback = false;
  
  // Stream subscription to prevent multiple listeners
  StreamSubscription? _audioCompleteSubscription;

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

  Future<void> _playAudio() async {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
    });

    try {
      final String audioFile = _currentLevel == 1 ? 'Knockrythm1' : 'Knockrythm2';
      
      // Cancel any existing subscription first
      await _audioCompleteSubscription?.cancel();
      
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/$audioFile.mp3'));
      
      // Create a new subscription and store it
      _audioCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
          
          // Move to next step after audio completes
          if (_currentStep == 'listen1') {
            _showQuizDialog();
          } else if (_currentStep == 'listen2') {
            setState(() {
              _currentStep = 'knock';
            });
          }
        }
      });

    } catch (e) {
      debugPrint('Error playing audio: $e');
      setState(() {
        _isPlaying = false;
      });
      
      // Still move forward even if audio fails
      if (_currentStep == 'listen1') {
        _showQuizDialog();
      } else if (_currentStep == 'listen2') {
        setState(() {
          _currentStep = 'knock';
        });
      }
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
            'correct': 2,
          }
        : {
            'question': 'What did this knocking rhythm remind you of?',
            'options': ['A: Long, Long Ago', 'B: May Song', 'C: Winter Serenade'],
            'correct': 1,
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
    final correctAnswer = _currentLevel == 1 ? 'C: O Come, Little Children' : 'B: May Song';

    if (!isCorrect) {
      // Show wrong answer
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
              'The correct answer was:\n$correctAnswer\n\nLet\'s listen again!',
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
        }
      }
    } else {
      // Show correct answer
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
              'Correct!\n\nNow listen again and try to knock the rhythm!',
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
            _currentStep = 'listen2';
          });
        }
      }
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

    int expectedTaps = (_expectedIntervals[_currentLevel]?.length ?? 0) + 1;
    if (_userTapTimestamps.length >= expectedTaps) {
      _stopRecording();
    }
  }

  void _stopRecording() {
    if (!_isRecording || _userTapTimestamps.length < 2) return;

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

    if (_userTapIntervals.length != expected.length) {
      setState(() {
        _success = false;
        _showResult = true;
      });
      return;
    }

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
      _onRhythmSuccess();
    }
  }

  Future<void> _onRhythmSuccess() async {
    if (_currentLevel == 1) {
      // Move to level 2
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
              'Great job! But the door needs a secret knock...\n\nTry the second pattern!',
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
            _currentStep = 'listen1';
            _showResult = false;
          });
        }
      }
    } else {
      // Challenge complete!
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
    _audioCompleteSubscription?.cancel();
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

              // Instructions
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.red[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  _getInstructionText(),
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: screenHeight * 0.01),

              // Door image with knock button overlay
              SizedBox(
                width: screenWidth * 0.7,
                height: screenWidth * 0.7 * 1.5,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
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

                    // Knock button (only when recording)
                    if (_isRecording)
                      GestureDetector(
                        onTap: _onTap,
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: screenWidth * 0.48,
                            height: screenWidth * 0.48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _showTapFeedback ? Colors.red[700] : Colors.red[900],
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

              // Controls based on current step
              if (_currentStep == 'listen1' && !_isPlaying)
                ElevatedButton.icon(
                  onPressed: _playAudio,
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
                  icon: Icon(Icons.volume_up, size: screenWidth * 0.08, color: Colors.white),
                  label: Text(
                    'Listen to the Rhythm',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

              if (_isPlaying)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hearing, color: Colors.blue[700], size: screenWidth * 0.08),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      'Listening...',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),

              if (_currentStep == 'listen2' && !_isPlaying)
                ElevatedButton.icon(
                  onPressed: _playAudio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.08,
                      vertical: screenHeight * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.volume_up, size: screenWidth * 0.08, color: Colors.white),
                  label: Text(
                    'Listen Again',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

              if (_currentStep == 'knock' && !_isRecording && !_showResult)
                Column(
                  children: [
                    ElevatedButton(
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
                    SizedBox(height: screenHeight * 0.015),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentStep = 'listen2';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.08,
                          vertical: screenHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(Icons.replay, size: screenWidth * 0.06, color: Colors.white),
                      label: Text(
                        'Listen Once More',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

              // Knock counter
              if (_isRecording)
                Text(
                  'Knocks: ${_userTapTimestamps.length}/${(_expectedIntervals[_currentLevel]?.length ?? 0) + 1}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),

              // Failed attempt - retry option
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
                              setState(() {
                                _success = true;
                              });
                              _onRhythmSuccess();
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
                                _currentStep = 'listen2';
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

              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  String _getInstructionText() {
    switch (_currentStep) {
      case 'listen1':
        return _currentLevel == 1
            ? 'You reached the castle, but the doors are closed.\n\nListen to the rhythm to unlock the door!'
            : 'Almost there! Listen to the secret knock pattern!';
      case 'quiz':
        return 'Which song does this remind you of?';
      case 'listen2':
        return 'Great! Now listen again carefully...';
      case 'knock':
        return _isRecording 
            ? 'Knock the rhythm!'
            : 'Now knock the rhythm on the door!';
      default:
        return 'Try the rhythm!';
    }
  }
}