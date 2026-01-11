import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_testapplication/services/storage_service.dart';
import '../practice_finished.dart';

class QuestionChallenge extends StatefulWidget {
  final bool isReplay;
  
  const QuestionChallenge({super.key, this.isReplay = false});

  @override
  State<QuestionChallenge> createState() => _QuestionChallengeState();
}

class _QuestionChallengeState extends State<QuestionChallenge> 
    with TickerProviderStateMixin {
  int _currentTokens = 0;
  int _currentQuestion = 0;
  int _correctAnswers = 0;
  bool _hasAnswered = false;
  bool _isPlaying = false;
  String _feedbackMessage = '';
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  late AnimationController _pulseController;
  late AnimationController _feedbackController;
  
  // Floating button positions and velocities
  final Random _random = Random();
  late Offset _happyPosition;
  late Offset _sadPosition;
  late Offset _happyVelocity;
  late Offset _sadVelocity;
  late Timer _floatingTimer;
  final double _buttonSize = 100;
  
  // Question bank with audio files and correct answers
  final List<Question> _questions = [
    Question(audioPath: 'audio/Major.mp3', isMajor: true, name: 'Major Scale'),
    Question(audioPath: 'audio/Major-Pentacord.mp3', isMajor: true, name: 'Major Pentacord'),
    Question(audioPath: 'audio/Minor-Pentacord.mp3', isMajor: false, name: 'Minor Pentacord'),
    Question(audioPath: 'audio/DMajor_Arpeggio.mp3', isMajor: true, name: 'D Major Arpeggio'),
    Question(audioPath: 'audio/DMinor_Arpeggio.mp3', isMajor: false, name: 'D Minor Arpeggio'),
    Question(audioPath: 'audio/AMinor_Arpeggio.mp3', isMajor: false, name: 'A Minor Arpeggio'),
  ];

  @override
  void initState() {
    super.initState();
    _loadTokens();
    _questions.shuffle();
    
    // Animation controllers
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Initialize floating button positions
    _initializeFloatingButtons();
    
    // Unlock challenge
    if (!widget.isReplay) {
      StorageService.unlockChallenge('question_challenge');
    }
    
    // Show introduction dialog, then start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showIntroDialog();
    });
  }
  
  void _initializeFloatingButtons() {
    _happyPosition = Offset(_random.nextDouble() * 200 + 50, _random.nextDouble() * 200 + 200);
    _sadPosition = Offset(_random.nextDouble() * 200 + 200, _random.nextDouble() * 200 + 200);
    _happyVelocity = Offset(_random.nextDouble() * 2 + 1, _random.nextDouble() * 2 + 1);
    _sadVelocity = Offset(_random.nextDouble() * 2 + 1, _random.nextDouble() * 2 + 1);
    
    _floatingTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (mounted) {
        _updateFloatingButtons();
      }
    });
  }
  
  void _updateFloatingButtons() {
    setState(() {
      // Update positions
      _happyPosition += _happyVelocity;
      _sadPosition += _sadVelocity;
      
      // Get screen bounds
      final size = MediaQuery.of(context).size;
      final maxX = size.width - _buttonSize;
      final maxY = size.height - _buttonSize - 200; // Account for header
      
      // Bounce off walls
      if (_happyPosition.dx <= 0 || _happyPosition.dx >= maxX) {
        _happyVelocity = Offset(-_happyVelocity.dx, _happyVelocity.dy);
        _happyPosition = Offset(_happyPosition.dx.clamp(0, maxX), _happyPosition.dy);
      }
      if (_happyPosition.dy <= 0 || _happyPosition.dy >= maxY) {
        _happyVelocity = Offset(_happyVelocity.dx, -_happyVelocity.dy);
        _happyPosition = Offset(_happyPosition.dx, _happyPosition.dy.clamp(0, maxY));
      }
      
      if (_sadPosition.dx <= 0 || _sadPosition.dx >= maxX) {
        _sadVelocity = Offset(-_sadVelocity.dx, _sadVelocity.dy);
        _sadPosition = Offset(_sadPosition.dx.clamp(0, maxX), _sadPosition.dy);
      }
      if (_sadPosition.dy <= 0 || _sadPosition.dy >= maxY) {
        _sadVelocity = Offset(_sadVelocity.dx, -_sadVelocity.dy);
        _sadPosition = Offset(_sadPosition.dx, _sadPosition.dy.clamp(0, maxY));
      }
    });
  }
  
  void _showIntroDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFDAA520),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red[900]!, width: 3),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Text(
                'Well done so far. You have more questions to answer!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Have you heard of Major and Minor?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'This is knight Major.\nMajor uses notes that sound open and bright.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'This is knight Minor.\nMinor uses notes that sound more serious or sad.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/happy_sad.webp',
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Happy face on top left
                  Positioned(
                    left: 20,
                    top: 20,
                    child: const Text('😊', style: TextStyle(fontSize: 40)),
                  ),
                  // Sad face on top right
                  Positioned(
                    right: 20,
                    top: 20,
                    child: const Text('😢', style: TextStyle(fontSize: 40)),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _playCurrentQuestion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Let's Start!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadTokens() async {
    int tokens = await StorageService.loadTokens();
    setState(() {
      _currentTokens = tokens;
    });
  }

  Future<void> _playCurrentQuestion() async {
    if (_currentQuestion >= _questions.length) return;
    
    setState(() {
      _isPlaying = true;
    });
    
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(_questions[_currentQuestion].audioPath));
      
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    } catch (e) {
      print('Error playing audio: $e');
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _onAnswerSelected(bool selectedMajor) async {
    if (_hasAnswered) return;
    
    setState(() {
      _hasAnswered = true;
    });
    
    await _audioPlayer.stop();
    
    bool isCorrect = selectedMajor == _questions[_currentQuestion].isMajor;
    
    if (isCorrect) {
      _correctAnswers++;
      setState(() {
        _feedbackMessage = selectedMajor 
            ? "Yes, it is Major! You heard that it sounds quite happy. 😊"
            : "Yes, it is Minor! You heard that it sounds a bit sad. 😢";
      });
      _feedbackController.forward(from: 0);
    } else {
      setState(() {
        _feedbackMessage = "Not quite, try again! 🎵";
      });
      _feedbackController.forward(from: 0);
      
      // Allow retry - don't count as answered
      await Future.delayed(const Duration(milliseconds: 2000));
      setState(() {
        _hasAnswered = false;
        _feedbackMessage = '';
      });
      return;
    }
    
    await Future.delayed(const Duration(milliseconds: 2500));
    
    setState(() {
      _feedbackMessage = '';
    });
    
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _hasAnswered = false;
      });
      _playCurrentQuestion();
    } else {
      _onChallengeComplete();
    }
  }

  Future<void> _onChallengeComplete() async {
    _floatingTimer.cancel();
    await _audioPlayer.stop();
    
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
                ? 'Challenge Complete!\n\nScore: $_correctAnswers/${_questions.length}'
                : 'Challenge Complete!\n\nScore: $_correctAnswers/${_questions.length}\n\nYou earned 1 token!\nTotal tokens: $_currentTokens',
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
    _floatingTimer.cancel();
    _audioPlayer.dispose();
    _pulseController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;
    
    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: Text(
          'Major vs Minor Challenge',
          style: TextStyle(fontSize: isSmallScreen ? 18 : 22),
        ),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(size.width * 0.05),
                child: Column(
                  children: [
                    _buildHeader(size, isSmallScreen),
                    SizedBox(height: size.height * 0.02),
                    _buildQuestionArea(size, isSmallScreen),
                    if (_feedbackMessage.isNotEmpty) ...[
                      SizedBox(height: size.height * 0.02),
                      _buildFeedback(size),
                    ],
                    SizedBox(height: size.height * 0.4),
                  ],
                ),
              ),
            ),
            // Floating answer buttons
            if (!_hasAnswered || _feedbackMessage == "Not quite, try again! 🎵")
              ..._buildFloatingButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Size size, bool isSmallScreen) {
    return Column(
      children: [
        Text(
          'Does this sound happy or sad?',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB22222),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: size.height * 0.02),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[900]!, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_note, color: Colors.red[900], size: isSmallScreen ? 18 : 20),
              const SizedBox(width: 8),
              Text(
                'Question: ${_currentQuestion + 1}/${_questions.length}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionArea(Size size, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.02,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[700]!, Colors.red[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPlaying ? 1.0 + (_pulseController.value * 0.1) : 1.0,
                child: Icon(
                  _isPlaying ? Icons.volume_up : Icons.play_circle_outline,
                  size: isSmallScreen ? 40 : 50,
                  color: Colors.white,
                ),
              );
            },
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            _isPlaying ? 'Listening...' : 'Tap to replay',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: size.height * 0.008),
          ElevatedButton.icon(
            onPressed: _isPlaying || _hasAnswered ? null : _playCurrentQuestion,
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('Replay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red[900],
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 6 : 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback(Size size) {
    return AnimatedBuilder(
      animation: _feedbackController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_feedbackController.value * 0.2),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _feedbackMessage.contains("Yes") 
                  ? Colors.green[600] 
                  : Colors.orange[700],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              _feedbackMessage,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingButtons() {
    return [
      Positioned(
        left: _happyPosition.dx,
        top: _happyPosition.dy + 100,
        child: _build3DButton(
          emoji: '😊',
          label: 'Happy',
          color: Colors.amber[600]!,
          isMajor: true,
        ),
      ),
      Positioned(
        left: _sadPosition.dx,
        top: _sadPosition.dy + 100,
        child: _build3DButton(
          emoji: '😢',
          label: 'Sad',
          color: Colors.blue[700]!,
          isMajor: false,
        ),
      ),
    ];
  }

  Widget _build3DButton({
    required String emoji,
    required String label,
    required Color color,
    required bool isMajor,
  }) {
    return GestureDetector(
      onTap: () => _onAnswerSelected(isMajor),
      child: Container(
        width: _buttonSize,
        height: _buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.8),
              color,
              color.withOpacity(0.6),
            ],
            stops: const [0.0, 0.6, 1.0],
            center: const Alignment(-0.3, -0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(4, 8),
            ),
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.2),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 2),
              Text(
                isMajor ? 'Major' : 'Minor',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Question {
  final String audioPath;
  final bool isMajor;
  final String name;

  Question({
    required this.audioPath,
    required this.isMajor,
    required this.name,
  });
}