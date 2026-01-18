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

class _OpenGatesChallengeState extends State<OpenGatesChallenge> 
    with TickerProviderStateMixin {
  int _currentTokens = 0;
  int _currentLevel = 1;
  bool _isPlaying = false;
  bool _hasAnsweredQuiz = false;
  bool _showKnockButton = false;
  bool _isRecording = false;
  bool _showTapFeedback = false;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final List<int> _knockTimestamps = [];
  final int _tolerance = 200;
  
  final Map<int, List<int>> _expectedIntervals = {
    1: [350, 700, 350, 350, 700, 350, 350, 700, 350, 350], // 11 knocks
    2: [850, 300, 650, 600, 600, 350, 300], // 8 knocks
  };

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    _loadTokens();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    if (!widget.isReplay) {
      StorageService.unlockChallenge('opengates_challenge');
    }
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      
      await _audioPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: [AVAudioSessionOptions.mixWithOthers],
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
    } catch (e) {
      // Audio setup failed
    }
  }

  Future<void> _loadTokens() async {
    int tokens = await StorageService.loadTokens();
    setState(() {
      _currentTokens = tokens;
    });
  }

  Future<void> _playAudio() async {
    setState(() {
      _isPlaying = true;
    });
    
    try {
      await _audioPlayer.stop();
      await Future.delayed(const Duration(milliseconds: 300));
      
      String audioPath = _currentLevel == 1 
          ? 'audio/knockrythm1.mp3' 
          : 'audio/knockrythm2.mp3';
      
      await _audioPlayer.play(AssetSource(audioPath));
      
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _onQuizAnswerSelected(int selectedIndex) {
    if (_hasAnsweredQuiz) return;
    
    setState(() {
      _hasAnsweredQuiz = true;
    });
    
    final quizData = _getQuizData();
    bool isCorrect = selectedIndex == quizData['correct'];
    
    String message;
    if (isCorrect) {
      message = 'Correct!\n\nNow listen to the rhythm and try to knock it!';
    } else {
      String correctAnswer = quizData['options'][quizData['correct']];
      message = 'The correct answer was:\n$correctAnswer\n\nLet\'s listen to the rhythm!';
    }
    
    _showDialog(
      message,
      onDismiss: () {
        setState(() {
          _showKnockButton = true;
        });
      },
    );
  }

  Map<String, dynamic> _getQuizData() {
    return _currentLevel == 1
        ? {
            'question': 'What does this rhythm remind you of?',
            'options': [
              'A: Song of the Wind',
              'B: Go Tell Aunt Rhody',
              'C: O Come, Little Children'
            ],
            'correct': 2,
          }
        : {
            'question': 'What does this rhythm remind you of?',
            'options': ['A: Long, Long Ago', 'B: May Song', 'C: Winter Serenade'],
            'correct': 1,
          };
  }

  void _startKnocking() {
    setState(() {
      _isRecording = true;
      _knockTimestamps.clear();
    });
  }

  void _onTap() {
    if (!_isRecording) return;
    
    setState(() {
      _showTapFeedback = true;
    });
    
    _knockTimestamps.add(DateTime.now().millisecondsSinceEpoch);
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _showTapFeedback = false;
        });
      }
    });
  }

  void _stopKnocking() {
    setState(() {
      _isRecording = false;
    });
    
    if (_knockTimestamps.length < 2) {
      _showDialog('Please tap at least 2 times to create a rhythm!');
      return;
    }
    
    _validateKnocking();
  }

  void _validateKnocking() {
    List<int> intervals = [];
    for (int i = 1; i < _knockTimestamps.length; i++) {
      intervals.add(_knockTimestamps[i] - _knockTimestamps[i - 1]);
    }
    
    List<int> expectedIntervals = _expectedIntervals[_currentLevel]!;
    
    if (intervals.length != expectedIntervals.length) {
      _showIncorrectDialog();
      return;
    }
    
    bool isCorrect = true;
    for (int i = 0; i < intervals.length; i++) {
      if ((intervals[i] - expectedIntervals[i]).abs() > _tolerance) {
        isCorrect = false;
        break;
      }
    }
    
    if (isCorrect) {
      _onCorrectKnocking();
    } else {
      _showIncorrectDialog();
    }
  }

  void _showIncorrectDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFDAA520),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red[900]!, width: 3),
        ),
        content: Text(
          'Not quite, do you want to try again or move on?',
          style: TextStyle(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
            color: Colors.red[900],
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _knockTimestamps.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: screenWidth * 0.03,
                  ),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(fontSize: screenWidth * 0.04),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _moveToNextLevel();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: screenWidth * 0.03,
                  ),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(fontSize: screenWidth * 0.04),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onCorrectKnocking() {
    String message = _currentLevel == 1
        ? 'Great job! But the door is not opening. It must have been the wrong pattern. Try the second one!'
        : 'Great job, the door is opening. ';
    
    _showDialog(
      message,
      onDismiss: () {
        if (_currentLevel == 1) {
          _moveToNextLevel();
        } else {
          _onChallengeComplete();
        }
      },
    );
  }

  void _moveToNextLevel() {
    if (_currentLevel == 1) {
      setState(() {
        _currentLevel = 2;
        _hasAnsweredQuiz = false;
        _showKnockButton = false;
        _knockTimestamps.clear();
      });
    } else {
      _onChallengeComplete();
    }
  }

  Future<void> _onChallengeComplete() async {
    await _audioPlayer.stop();
    
    if (!widget.isReplay) {
      await _addToken();
    }

    if (mounted) {
      final screenWidth = MediaQuery.of(context).size.width;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.red[700]!,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white, width: 3),
          ),
          content: Text(
            widget.isReplay
                ? 'Congratulations, you are granted access to the castle!\n\nThe doors are open!'
                : 'Congratulations, you are granted access to the castle!\n\nThe doors are open!\n\nYou earned one token!\nYou now have a total of $_currentTokens tokens!',
            style: TextStyle(
              fontSize: screenWidth * 0.05,
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
        if (widget.isReplay) {
          Navigator.of(context).pop();
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const GoalReached()),
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

  void _showDialog(String message, {VoidCallback? onDismiss}) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFDAA520),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red[900]!, width: 3),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
            color: Colors.red[900],
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onDismiss != null) onDismiss();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: screenWidth * 0.03,
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(fontSize: screenWidth * 0.045),
              ),
            ),
          ),
        ],
      ),
    );
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
        title: Text(
          'Open the Castle Gates - Level $_currentLevel',
          style: TextStyle(fontSize: screenWidth * 0.045),
        ),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.02),
              
              // Instruction text (only show on level 1)
              if (_currentLevel == 1) ...[
                Text(
                  'You reached the castle, but the doors are closed. You need the correct knocking pattern so that someone lets you in.',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.03),
              ],

              // Door image with optional knock button overlay
              SizedBox(
                width: screenWidth * 0.525,
                height: screenWidth * 0.525 * 1.5,
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
                            width: screenWidth * 0.525,
                            height: screenWidth * 0.525 * 1.5,
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
                            width: screenWidth * 0.36,
                            height: screenWidth * 0.36,
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
                                    size: screenWidth * 0.09,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: screenHeight * 0.005),
                                  Text(
                                    'KNOCK\nHERE',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.038,
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

              // Knock counter below the door
              if (_isRecording) ...[
                SizedBox(height: screenHeight * 0.02),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    'Knocks: ${_knockTimestamps.length}/${_expectedIntervals[_currentLevel]!.length + 1}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              SizedBox(height: screenHeight * 0.03),

              // Buttons based on current state
              if (!_hasAnsweredQuiz) ...[
                ElevatedButton.icon(
                  onPressed: _isPlaying ? null : _playAudio,
                  icon: Icon(
                    _isPlaying ? Icons.volume_up : Icons.play_arrow,
                    size: screenWidth * 0.06,
                  ),
                  label: Text(
                    _isPlaying ? 'Playing...' : 'Listen to the rhythm',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.08,
                      vertical: screenHeight * 0.02,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                
                // Quiz section
                _buildQuizSection(screenWidth),
              ] else if (_showKnockButton) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isPlaying ? null : _playAudio,
                      icon: Icon(
                        _isPlaying ? Icons.volume_up : Icons.replay,
                        size: screenWidth * 0.05,
                      ),
                      label: Text(
                        _isPlaying ? 'Playing...' : 'Listen',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.015,
                        ),
                      ),
                    ),
                    if (_isRecording) ...[
                      SizedBox(width: screenWidth * 0.03),
                      ElevatedButton(
                        onPressed: _stopKnocking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenHeight * 0.015,
                          ),
                        ),
                        child: Text(
                          'Done Knocking',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                
                if (!_isRecording)
                  ElevatedButton(
                    onPressed: _startKnocking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.08,
                        vertical: screenHeight * 0.02,
                      ),
                    ),
                    child: Text(
                      'Ready to Knock',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizSection(double screenWidth) {
    final quizData = _getQuizData();
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.035),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[900]!, width: 2),
      ),
      child: Column(
        children: [
          Text(
            quizData['question'],
            style: TextStyle(
              fontSize: screenWidth * 0.038,
              fontWeight: FontWeight.bold,
              color: Colors.red[900],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenWidth * 0.03),
          ...List.generate(
            quizData['options'].length,
            (index) => Padding(
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
              child: ElevatedButton(
                onPressed: () => _onQuizAnswerSelected(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, screenWidth * 0.1),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenWidth * 0.025,
                  ),
                ),
                child: Text(
                  quizData['options'][index],
                  style: TextStyle(fontSize: screenWidth * 0.035),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}