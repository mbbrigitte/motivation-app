import 'package:flutter/material.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:flutter_testapplication/services/storage_service.dart';
import '../practice_finished.dart';

class PostureChallenge extends StatefulWidget {
  final bool isReplay;
  
  const PostureChallenge({super.key, this.isReplay = false});

  @override
  State<PostureChallenge> createState() => _PostureChallengeState();
}

class _PostureChallengeState extends State<PostureChallenge> with TickerProviderStateMixin {
  int _currentTokens = 0;
  int _currentQuestion = 0;
  String? _selectedAnswer;
  bool _showFeedback = false;
  bool _isCorrect = false;
  
  // Video controllers
  VideoPlayerController? _leftVideoController;
  VideoPlayerController? _rightVideoController;
  bool _leftVideoInitialized = false;
  bool _rightVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadTokens();
    
    // Unlock this challenge when first accessed (not in replay mode)
    if (!widget.isReplay) {
      StorageService.unlockChallenge('posture_challenge');
    }
  }

  Future<void> _loadTokens() async {
    int tokens = await StorageService.loadTokens();
    setState(() {
      _currentTokens = tokens;
    });
  }

  Future<void> _initializeVideos(String leftVideo, String rightVideo) async {
    // Dispose of old controllers if they exist
    await _leftVideoController?.dispose();
    await _rightVideoController?.dispose();
    
    setState(() {
      _leftVideoInitialized = false;
      _rightVideoInitialized = false;
    });

    _leftVideoController = VideoPlayerController.asset('assets/videos/$leftVideo');
    _rightVideoController = VideoPlayerController.asset('assets/videos/$rightVideo');

    await _leftVideoController!.initialize();
    await _rightVideoController!.initialize();

    setState(() {
      _leftVideoInitialized = true;
      _rightVideoInitialized = true;
    });
  }

  void _onImageSelected(String answer) {
    setState(() {
      _selectedAnswer = answer;
      _showFeedback = true;
      _isCorrect = _getCorrectAnswer() == answer;
    });

    // Determine wait time based on question and answer
    int waitSeconds = 5;
    if (_currentQuestion == 2 && answer == 'sitting') {
      // Sitting answer needs extra time to read
      waitSeconds = 7;
    }

    if (_isCorrect) {
      // Wait for correct answer, then move to next question
      Future.delayed(Duration(seconds: waitSeconds), () {
        if (mounted) {
          _moveToNextQuestion();
        }
      });
    } else {
      // If wrong, wait then allow them to try again
      Future.delayed(Duration(seconds: waitSeconds), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
            _selectedAnswer = null;
          });
        }
      });
    }
  }

  void _onVideoAnswerSelected(String answer) {
    setState(() {
      _selectedAnswer = answer;
      _showFeedback = true;
      _isCorrect = _getCorrectAnswer() == answer;
    });

    if (_isCorrect) {
      // If correct, move to next question after 5 seconds (extra time to read)
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _moveToNextQuestion();
        }
      });
    } else {
      // Determine wait time - bad posture video needs extra time
      int waitSeconds = 4;
      if (_currentQuestion == 3) {
        // Bad posture video needs more time to read longer message
        waitSeconds = 6;
      }
      
      // If wrong, wait then allow them to try again
      Future.delayed(Duration(seconds: waitSeconds), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
            _selectedAnswer = null;
          });
        }
      });
    }
  }

  String _getCorrectAnswer() {
    switch (_currentQuestion) {
      case 0:
        return 'good';
      case 1:
        return 'goodbow';
      case 2:
        return 'standing';
      case 3:
        return 'goodposture';
      default:
        return '';
    }
  }

  void _moveToNextQuestion() {
    setState(() {
      _showFeedback = false;
      _selectedAnswer = null;
      _currentQuestion++;
    });

    if (_currentQuestion == 4) {
      _onChallengeComplete();
    } else if (_currentQuestion == 1 || _currentQuestion == 3) {
      // Initialize videos for questions 1 and 3
      if (_currentQuestion == 1) {
        _initializeVideos('BadBow_lowres.mp4', 'GoodBow_lowres.mp4');
      } else {
        _initializeVideos('BadPosture_lowres.mp4', 'GoodPosture_lowres.mp4');
      }
    }
  }

  Future<void> _onChallengeComplete() async {
    // Only award tokens if not in replay mode
    if (!widget.isReplay) {
      await _addToken();
    }

    if (mounted) {
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
                ? 'Great job! Remember the good posture and bow hold for next time. After you close this app, play a little bit using your best bow hand!'
                : 'Great job! Remember the good posture and bow hold for next time. After you close this app, play a little bit using your best bow hand. You get 1 extra token for it!\n\nYou now have a total of $_currentTokens tokens!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 8));

      if (mounted) {
        Navigator.of(context).pop();
        if (widget.isReplay) {
          Navigator.of(context).pop();
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PracticeFinished()),
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
    _leftVideoController?.dispose();
    _rightVideoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: Text(
          'The Posture Challenge',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          child: Column(
            children: [
              SizedBox(height: isSmallScreen ? 10 : 20),
              Text(
                'The violinist played really nice. A good posture is important to play well and not hurt yourself.',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFB22222),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 20 : 30),
              _buildCurrentQuestion(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentQuestion() {
    switch (_currentQuestion) {
      case 0:
        return _buildImageQuestion(
          'Which one has a good posture? Click on it!',
          'assets/images/badposture.jpeg',
          'assets/images/goodposture.jpeg',
          'bad',
          'good',
          'Correct! Straight back.',
          'Not quite. This person is slouching. We need a straight back to play the violin.',
        );
      case 1:
        return _buildVideoQuestion(
          'Which video shows a good bow hold?',
          'badbowhold',
          'goodbow',
          'Well done! Yes, a nice and round bow hand is best for playing the violin nicely.',
          'Not quite, watch the two videos again.',
        );
      case 2:
        return _buildImageQuestion(
          'Which position is better for practicing?',
          'assets/images/sitting.webp',
          'assets/images/standing.webp',
          'sitting',
          'standing',
          'Exactly! We can have better posture and play better when we stand.',
          'Sometimes, we need to sit because we play in an orchestra. But it is better to practice standing up.',
        );
      case 3:
        return _buildVideoQuestion(
          'Which video shows good posture?',
          'badposture',
          'goodposture',
          'Perfect! This is excellent posture for playing the violin.',
          'Not quite. The violin is a bit too low. Watch the two videos again.',
        );
      default:
        return Container();
    }
  }

  Widget _buildImageQuestion(
    String question,
    String leftImage,
    String rightImage,
    String leftAnswer,
    String rightAnswer,
    String correctMessage,
    String wrongMessage,
  ) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final imageHeight = isSmallScreen ? 220.0 : 320.0;
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey(_currentQuestion),
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 20 : 30),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showFeedback ? null : () => _onImageSelected(leftAnswer),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _showFeedback && _selectedAnswer == leftAnswer
                                ? (_isCorrect ? Colors.green : Colors.red)
                                : Colors.white,
                            width: 5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            leftImage,
                            fit: BoxFit.contain,
                            height: imageHeight,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      if (_showFeedback && _selectedAnswer == leftAnswer && !_isCorrect)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  wrongMessage,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 20),
              Expanded(
                child: GestureDetector(
                  onTap: _showFeedback ? null : () => _onImageSelected(rightAnswer),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _showFeedback && _selectedAnswer == rightAnswer
                                ? (_isCorrect ? Colors.green : Colors.red)
                                : Colors.white,
                            width: 5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            rightImage,
                            fit: BoxFit.contain,
                            height: imageHeight,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      if (_showFeedback && _selectedAnswer == rightAnswer && !_isCorrect)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  wrongMessage,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showFeedback && _isCorrect)
            Padding(
              padding: EdgeInsets.only(top: isSmallScreen ? 15 : 20),
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Text(
                  correctMessage,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoQuestion(
    String question,
    String leftAnswer,
    String rightAnswer,
    String correctMessage,
    String wrongMessage,
  ) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final videoHeight = isSmallScreen ? 150.0 : 200.0;
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey(_currentQuestion),
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 20 : 30),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: videoHeight,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: _leftVideoInitialized
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AspectRatio(
                                aspectRatio: _leftVideoController!.value.aspectRatio,
                                child: VideoPlayer(_leftVideoController!),
                              ),
                            )
                          : const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 10),
                    ElevatedButton.icon(
                      onPressed: _leftVideoInitialized
                          ? () {
                              _leftVideoController!.seekTo(Duration.zero);
                              _leftVideoController!.play();
                            }
                          : null,
                      icon: Icon(Icons.play_arrow, size: isSmallScreen ? 18 : 24),
                      label: Text(
                        'Play Video',
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 20,
                          vertical: isSmallScreen ? 8 : 12,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 10),
                    ElevatedButton(
                      onPressed: _showFeedback ? null : () => _onVideoAnswerSelected(leftAnswer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red[900],
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 16,
                          vertical: isSmallScreen ? 8 : 12,
                        ),
                      ),
                      child: Text(
                        'Click here if this is good',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 20),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: videoHeight,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: _rightVideoInitialized
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AspectRatio(
                                aspectRatio: _rightVideoController!.value.aspectRatio,
                                child: VideoPlayer(_rightVideoController!),
                              ),
                            )
                          : const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 10),
                    ElevatedButton.icon(
                      onPressed: _rightVideoInitialized
                          ? () {
                              _rightVideoController!.seekTo(Duration.zero);
                              _rightVideoController!.play();
                            }
                          : null,
                      icon: Icon(Icons.play_arrow, size: isSmallScreen ? 18 : 24),
                      label: Text(
                        'Play Video',
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 20,
                          vertical: isSmallScreen ? 8 : 12,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 10),
                    ElevatedButton(
                      onPressed: _showFeedback ? null : () => _onVideoAnswerSelected(rightAnswer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red[900],
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 16,
                          vertical: isSmallScreen ? 8 : 12,
                        ),
                      ),
                      child: Text(
                        'Click here if this is good',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showFeedback)
            Padding(
              padding: EdgeInsets.only(top: isSmallScreen ? 15 : 20),
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: _isCorrect ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Text(
                  _isCorrect ? correctMessage : wrongMessage,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}