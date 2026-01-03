import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';
import 'dart:async';
//import '../../services/storage_service.dart';
import 'package:flutter_testapplication/services/storage_service.dart';
import '../practice_finished.dart';

class BachChallenge extends StatefulWidget {
  final bool isReplay;
  
  const BachChallenge({super.key, this.isReplay = false});

  @override
  State<BachChallenge> createState() => _BachChallengeState();
}

class _BachChallengeState extends State<BachChallenge> with TickerProviderStateMixin {
  int _currentQuestion = 0;
  int _correctAnswers = 0;
  int _currentTokens = 0;
  bool _answered = false;
  String? _selectedAnswer;
  AudioPlayer? _audioPlayer;
  late AnimationController _tokenController;
  late AnimationController _bowController;
  List<AnimationController> _sparkleControllers = [];
  Uint8List? _currentImageData;
  bool _isLoadingImage = false;
  VideoPlayerController? _videoController;
  bool _showVideo = false;
  bool _showIntro = true;
  bool _videoPausedAtEnd = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'type': 'image',
      'question': 'What is the rest in this music?',
      'image': 'assets/images/eighth_rest.png',
      'options': ['Quarter rest', 'Eighth rest', 'Half rest', 'Whole rest'],
      'correct': 'Eighth rest',
    },
    {
      'type': 'audio',
      'question': 'What song is this?',
      'audio': 'audio/guess_lightlyrow.mp3',
      'options': ['Allegro', 'Lightly Row', 'Lightly Stir', 'Song of the Wind'],
      'correct': 'Lightly Row',
    },
    {
      'type': 'image',
      'question': 'Which of these notes can not be played with an empty string?',
      'image': 'assets/images/guess_empty_strings.png',
      'options': ['1', '2', '3', '4', '5'],
      'correct': '3',
    },
    {
      'type': 'image',
      'question': 'What note appears most in this piece?',
      'image': 'assets/images/quater_eight_note.png',
      'options': ['Quarter note', 'Eighth note', 'Half note', 'Whole note'],
      'correct': 'Eighth note',
    },
    {
      'type': 'text',
      'question': 'What does "pizzicato" mean?',
      'options': ['Play loudly', 'Pluck the strings', 'Play softly', 'Use the bow'],
      'correct': 'Pluck the strings',
    },
    {
      'type': 'text',
      'question': 'What does "allegro" mean?',
      'options': ['Very slow', 'Medium speed', 'Fast and lively', 'Gradually slower'],
      'correct': 'Fast and lively',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadTokens();
    _initializeAnimations();
    _loadCurrentQuestionContent();
    
    // Unlock this challenge when first accessed (not in replay mode)
    if (!widget.isReplay) {
      StorageService.unlockChallenge('bach_challenge');
    }
  }

  void _initializeAnimations() {
    _tokenController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _bowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create sparkle controllers for each correct answer
    for (int i = 0; i < _questions.length; i++) {
      _sparkleControllers.add(
        AnimationController(
          duration: const Duration(milliseconds: 1500),
          vsync: this,
        )..repeat(reverse: true),
      );
    }
  }

  Future<void> _loadTokens() async {
    int tokens = await StorageService.loadTokens();
    setState(() {
      _currentTokens = tokens;
    });
  }

  Future<void> _loadCurrentQuestionContent() async {
    final question = _questions[_currentQuestion];
    
    if (question['type'] == 'image') {
      setState(() {
        _isLoadingImage = true;
      });
      
      try {
        // Load PNG image as bytes
        final ByteData data = await rootBundle.load(question['image']);
        setState(() {
          _currentImageData = data.buffer.asUint8List();
          _isLoadingImage = false;
        });
      } catch (e) {
        print('Error loading image: $e');
        setState(() {
          _isLoadingImage = false;
        });
      }
    }
  }

  void _videoEndListener() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    
    final duration = _videoController!.value.duration;
    final position = _videoController!.value.position;
    
    // When video reaches the end, pause it
    if (position >= duration && !_videoPausedAtEnd) {
      _videoController!.pause();
      _videoPausedAtEnd = true;
      print('Video paused at last frame');
    }
  }

  Future<void> _playAudio() async {
    try {
      _audioPlayer?.stop();
      _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();
      
      final audioPath = _questions[_currentQuestion]['audio'] as String;
      print('Playing audio: $audioPath');
      
      await _audioPlayer!.play(AssetSource(audioPath));
    } catch (e) {
      print('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not play audio: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleAnswer(String answer) async {
    if (_answered) return;

    setState(() {
      _answered = true;
      _selectedAnswer = answer;
    });

    final isCorrect = answer == _questions[_currentQuestion]['correct'];

    if (isCorrect) {
      setState(() {
        _correctAnswers++;
      });
      _tokenController.forward(from: 0);
      _bowController.forward();
    }

    await Future.delayed(const Duration(seconds: 2));

    // Stop audio if playing
    _audioPlayer?.stop();

    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _answered = false;
        _selectedAnswer = null;
        _currentImageData = null;
      });
      _audioPlayer?.dispose();
      _audioPlayer = null;
      await _loadCurrentQuestionContent();
    } else {
      // Last question answered - show results with video
      await _showResults();
    }
  }

  Future<void> _showResults() async {
    // Only award tokens if not in replay mode
    if (!widget.isReplay) {
      await _addTokens(_correctAnswers);
    }

    if (!mounted) return;

    print('=== INITIALIZING BACH VIDEO ===');
    print('Video path: assets/videos/Bach_gets_up_happy.mp4');
    
    try {
      // Initialize Bach video
      _videoController = VideoPlayerController.asset('assets/videos/Bach_gets_up_happy.mp4');
      await _videoController!.initialize();
      print('Bach video initialized successfully!');
      
      // Set playback speed to 0.8 (slower)
      await _videoController!.setPlaybackSpeed(0.7);
      
      // Add listener to pause at the last frame
      _videoController!.addListener(_videoEndListener);
      
      setState(() {
        _showVideo = true;
      });
      
      // Play the video
      await _videoController!.play();
      print('Bach video is now playing');
    } catch (e) {
      print('ERROR loading Bach video: $e');
    }

    if (!mounted) return;

    // Show message UNDER the video - with no barrier overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent, // Remove dark overlay
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Video takes most of the space
            Expanded(
              flex: 3,
              child: Container(), // Video is shown in the Stack overlay
            ),
            // Message at the bottom
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.yellow[700],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Text(
                '🎵 Johann is happy with your answers! 🎵',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB22222),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    // Wait for video to finish, then stay at last frame for 2 seconds
    // Video duration + 2 seconds pause at end
    await Future.delayed(const Duration(seconds: 10)); // Adjust based on your video length

    // Hide video
    if (mounted) {
      setState(() {
        _showVideo = false;
      });
    }

    if (!mounted) return;
    
    // Close the message dialog
    Navigator.of(context).pop();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Show final results dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.yellow[700]!,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white, width: 3),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎻 Quiz Complete! 🎻',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB22222),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'You answered $_correctAnswers out of ${_questions.length} correctly!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB22222),
              ),
              textAlign: TextAlign.center,
            ),
            if (!widget.isReplay) ...[
              const SizedBox(height: 10),
              Text(
                'You earned $_correctAnswers tokens!\nYou now have $_currentTokens tokens!',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFFB22222),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              '🎵 Well done! 🎵',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB22222),
              ),
              textAlign: TextAlign.center,
            ),
          ],
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

  Future<void> _addTokens(int tokensToAdd) async {
    int currentTokens = await StorageService.loadTokens();
    await StorageService.saveTokens(currentTokens + tokensToAdd);

    int totalTokens = await StorageService.loadTotalTokens();
    await StorageService.saveTotalTokens(totalTokens + tokensToAdd);

    int updatedTokens = await StorageService.loadTokens();

    setState(() {
      _currentTokens = updatedTokens;
    });
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _videoController?.removeListener(_videoEndListener);
    _videoController?.dispose();
    _tokenController.dispose();
    _bowController.dispose();
    for (var controller in _sparkleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildQuestionContent() {
    final question = _questions[_currentQuestion];
    
    return Column(
      children: [
        if (question['type'] == 'image') ...[
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.red[900]!, width: 3),
            ),
            child: _isLoadingImage
                ? const Center(child: CircularProgressIndicator())
                : _currentImageData != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _currentImageData!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : const Center(
                        child: Text(
                          'Image could not be loaded',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
          ),
        ] else if (question['type'] == 'audio') ...[
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow[600]!, Colors.orange[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.red[900]!, width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_note, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _playAudio,
                  icon: const Icon(Icons.play_arrow, size: 30),
                  label: const Text(
                    'Play Song',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[900],
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestion];
    final progress = (_currentQuestion + 1) / _questions.length;

    // Show intro screen first
    if (_showIntro) {
      return Scaffold(
        backgroundColor: const Color(0xFFDAA520),
        appBar: AppBar(
          title: const Text('Bach\'s Quiz Challenge'),
          backgroundColor: Colors.red[900],
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Image.asset(
                    'assets/images/Bach_on_Bench.webp',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red[900]!, width: 3),
                  ),
                  child: const Text(
                    'Johann Sebastian Bach is sitting on a bench. He has some questions for you. Can you answer them?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB22222),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showIntro = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 6,
                    ),
                    child: const Text(
                      'Start Quiz!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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

    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: const Text('Bach\'s Quiz Challenge'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Progress bar with bow
                  Stack(
                    children: [
                      Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.red[900]!, width: 2),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        height: 30,
                        width: MediaQuery.of(context).size.width * 0.9 * progress,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red[700]!, Colors.orange[500]!],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      Positioned(
                        left: (MediaQuery.of(context).size.width * 0.9 * progress) - 20,
                        top: -5,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset.zero,
                            end: const Offset(0, -0.2),
                          ).animate(CurvedAnimation(
                            parent: _bowController,
                            curve: Curves.easeInOut,
                          )),
                          child: const Text(
                            '🎻',
                            style: TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Token display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_correctAnswers, (index) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _sparkleControllers[index],
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [Colors.yellow[300]!, Colors.amber[600]!],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.yellow.withOpacity(0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '✨',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Question ${_currentQuestion + 1} of ${_questions.length}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[900],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.yellow[100],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red[900]!, width: 3),
                    ),
                    child: Text(
                      question['question'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB22222),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildQuestionContent(),

                  const SizedBox(height: 30),

                  ...List.generate(question['options'].length, (index) {
                    final option = question['options'][index];
                    final isSelected = _selectedAnswer == option;
                    final isCorrect = option == question['correct'];
                    
                    Color buttonColor;
                    if (_answered) {
                      if (isCorrect) {
                        buttonColor = Colors.green[600]!;
                      } else if (isSelected && !isCorrect) {
                        buttonColor = Colors.red[600]!;
                      } else {
                        buttonColor = Colors.grey[400]!;
                      }
                    } else {
                      buttonColor = Colors.red[700]!;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _answered ? null : () => _handleAnswer(option),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: _answered ? 2 : 6,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                option,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_answered && isCorrect)
                                const Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Icon(Icons.check_circle, size: 24),
                                ),
                              if (_answered && isSelected && !isCorrect)
                                const Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Icon(Icons.cancel, size: 24),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          
          // BACH VIDEO OVERLAY - Full screen when _showVideo is true
          if (_showVideo && _videoController != null && _videoController!.value.isInitialized)
            Positioned.fill(
              child: Container(
                color: Colors.white, // White background for maximum brightness
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}