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
  bool _hasPlayedFirstTime = false;
  bool _hasAnsweredQuiz = false;
  bool _hasPlayedSecondTime = false;
  bool _isRecording = false;
  bool _showResult = false;
  bool _success = false;
  int _currentLevel = 1;

  // Playback control flags
  bool _isSecondListenPlaying = false; // true when current play is second listen
  bool _quizShownForLevel = false; // ensure quiz only shown once per level

  // Tap recording
  List<int> _userTapTimestamps = [];
  List<int> _userTapIntervals = [];

  final Map<int, List<int>> _expectedIntervals = {
    1: [350, 700, 350, 350, 700, 350, 350, 700, 350, 350], // 10 intervals = 11 knocks
    2: [850, 300, 650, 600, 600, 350, 300], // 7 intervals = 8 knocks
  };

  final int _tolerance = 200;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showTapFeedback = false;

  @override
  void initState() {
    super.initState();
    _loadTokens();

    // Set audio mode for better Android compatibility
    _audioPlayer.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );

    // Attach onPlayerComplete listener ONCE to avoid multiple firings
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;

      setState(() {
        _isListening = false;

        // Only show the quiz on the first listen of the current level,
        // and only if the quiz hasn't already been shown and hasn't been answered.
        if (!_isSecondListenPlaying) {
          _hasPlayedFirstTime = true;
          if (!_quizShownForLevel && !_hasAnsweredQuiz) {
            _quizShownForLevel = true;
            // schedule showing the quiz after state settles
            Future.microtask(() => _showQuizDialog());
          }
        } else {
          _hasPlayedSecondTime = true;
        }
      });
    });

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

  Future<void> _playRhythmAudio({bool isSecondListen = false}) async {
    // prevent overlapping requests
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _isSecondListenPlaying = isSecondListen;
      // Only reset quizShown for a fresh "first listen" of the level
      if (!isSecondListen) {
        _quizShownForLevel = false;
        // Also reset answered flag so quiz can be answered for this level
        _hasAnsweredQuiz = false;
      }
    });

    try {
      final String audioFile = _currentLevel == 1 ? 'Knockrythm1' : 'Knockrythm2';

      // Stop any currently playing audio and reset mode
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);

      // Start playback
      await _audioPlayer.play(AssetSource('audio/$audioFile.mp3'));

      // Wait until playback actually starts (or timeout)
      final started = await Future.any([
        _audioPlayer.onPlayerStateChanged.firstWhere((s) => s == PlayerState.playing),
        Future.delayed(const Duration(seconds: 5), () => null),
      ]);

      if (started == null) {
        // playback didn't start in time -> handle as failure
        _handleAudioFailure(isSecondListen);
        return;
      }

      // If started, let onPlayerComplete handle the rest.
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _handleAudioFailure(isSecondListen);
    }
  }

  void _handleAudioFailure(bool isSecondListen) {
    if (!mounted) return;

    // Prevent the quiz from being shown multiple times via multiple failure paths
    final shouldShowQuiz = !isSecondListen && !_quizShownForLevel && !_hasAnsweredQuiz;

    setState(() {
      _isListening = false;
      if (!isSecondListen) {
        _hasPlayedFirstTime = true;
        if (shouldShowQuiz) {
          _quizShownForLevel = true;
        }
      } else {
        _hasPlayedSecondTime = true;
      }
    });

    if (shouldShowQuiz) {
      Future.microtask(() => _showQuizDialog());
    }
  }

  void _showQuizDialog() {
    // Safety: show only if not answered (and flag ensures it can't be called twice for the level)
    if (_hasAnsweredQuiz) return;

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

    setState(() {
      _hasAnsweredQuiz = true;
    });

    if (!isCorrect) {
      // Show correct answer and prompt to listen again
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
      // Correct answer
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
            // Reset relevant flags for level 2
            _hasPlayedFirstTime = false;
            _hasAnsweredQuiz = false;
            _hasPlayedSecondTime = false;
            _showResult = false;
            _quizShownForLevel = false;
            _isSecondListenPlaying = false;
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

              // Door with overlaid knock button
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

              // Step 1: First Listen Button
              if (!_hasPlayedFirstTime && !_isListening)
                ElevatedButton.icon(
                  onPressed: () => _playRhythmAudio(isSecondListen: false),
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
                    Icons.volume_up,
                    size: screenWidth * 0.08,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Listen to the Rhythm',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Listening indicator
              if (_isListening)
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.02),
                  child: Row(
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
                ),

              // Step 3: Second Listen Button (after quiz)
              if (_hasAnsweredQuiz && !_hasPlayedSecondTime && !_isListening)
                ElevatedButton.icon(
                  onPressed: () => _playRhythmAudio(isSecondListen: true),
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
                  icon: Icon(
                    Icons.volume_up,
                    size: screenWidth * 0.08,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Listen Again',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Step 4: Ready to Knock button AND Listen Once More
              if (_hasPlayedSecondTime && !_isRecording && !_showResult)
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.02),
                  child: Column(
                    children: [
                      // Ready to Knock button
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
                      // Listen Once More button
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _hasPlayedSecondTime = false;
                          });
                          _playRhythmAudio(isSecondListen: true);
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
                        icon: Icon(
                          Icons.replay,
                          size: screenWidth * 0.06,
                          color: Colors.white,
                        ),
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

              // Error message and retry
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
                                _hasPlayedSecondTime = false;
                                // keep _quizShownForLevel as-is: if quiz was shown, we don't want to show it again
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
    if (!_hasPlayedFirstTime) {
      if (_currentLevel == 1) {
        return 'You reached the castle, but the doors are closed.\n\nListen to the rhythm to unlock the door!';
      } else {
        return 'Almost there! Listen to the secret knock pattern!';
      }
    } else if (!_hasAnsweredQuiz) {
      return 'Which song does this remind you of?';
    } else if (!_hasPlayedSecondTime) {
      return 'Great! Now listen again carefully...';
    } else if (!_isRecording && !_showResult) {
      return 'Now knock the rhythm on the door!';
    } else if (_isRecording) {
      return 'Knock the rhythm!';
    } else {
      return 'Try the rhythm!';
    }
  }
}
