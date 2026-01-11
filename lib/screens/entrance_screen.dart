import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'quest_selection_screen.dart';
import 'package:flutter_testapplication/services/storage_service.dart';

class EntranceScreen extends StatefulWidget {
  const EntranceScreen({super.key});

  @override
  State<EntranceScreen> createState() => _EntranceScreenState();
}

class _EntranceScreenState extends State<EntranceScreen> {
  late VideoPlayerController _videoController;
  final AudioPlayer _violinPlayer = AudioPlayer();
  final AudioPlayer _knightPlayer = AudioPlayer();

  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  Timer? _fadeTimer;
  Timer? _knightTimer;
  Timer? _endTimer;
  
  // Tutorial state
  bool _showTutorial = false;
  int _tutorialPage = 0;
  bool _isCheckingFirstTime = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTimeUser();
    _initializeAudioPlayers();
    _initializeVideo();
  }

  Future<void> _checkFirstTimeUser() async {
    // Check if user has 0 tokens and 0 total tokens (first time)
    int tokens = await StorageService.loadTokens();
    int totalTokens = await StorageService.loadTotalTokens();
    
    setState(() {
      _showTutorial = (tokens == 0 && totalTokens == 0);
      _isCheckingFirstTime = false;
    });
  }

  // Configure audio players for Android compatibility
  Future<void> _initializeAudioPlayers() async {
    try {
      // CRITICAL: Use AudioFocus.none to NOT steal focus from video
      await _violinPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: [
              AVAudioSessionOptions.mixWithOthers,
            ],
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

      await _knightPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: [
              AVAudioSessionOptions.mixWithOthers,
            ],
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
    } catch (e) {
      print('Error configuring audio players: $e');
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset(
      'assets/videos/Knight_just_talks.mp4',
    );

    await _videoController.initialize();
    await _videoController.setLooping(false);
    await _videoController.pause();

    _videoController.addListener(_videoListener);

    setState(() => _isVideoInitialized = true);
  }

  void _videoListener() {
    final value = _videoController.value;

    if (_isPlaying &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      setState(() => _isPlaying = false);
      _videoController.seekTo(const Duration(milliseconds: 500));
      _videoController.pause();
    }
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    _violinPlayer.dispose();
    _knightPlayer.dispose();
    _fadeTimer?.cancel();
    _knightTimer?.cancel();
    _endTimer?.cancel();
    super.dispose();
  }

  void _startSequence() async {
    if (_isVideoInitialized && !_isPlaying) {
      setState(() => _isPlaying = true);

      _videoController.removeListener(_videoListener);
      await _videoController.seekTo(Duration.zero);

      await Future.delayed(const Duration(milliseconds: 100));
      _videoController.addListener(_videoListener);

      await _videoController.play();

      await Future.delayed(const Duration(milliseconds: 300));
    }

    await _violinPlayer.play(AssetSource('audio/intro1.mp3'));
    await _violinPlayer.seek(const Duration(seconds: 2));
    await _violinPlayer.setVolume(1.0);

    _knightTimer = Timer(const Duration(seconds: 7), () async {
      await _knightPlayer.play(AssetSource('audio/Audio_knight.m4a'));
      _startViolinFade();
    });

    _endTimer = Timer(const Duration(seconds: 18), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const QuestSelectionScreen()),
        );
      }
    });
  }

  void _startViolinFade() {
    const fadeSteps = 90;
    const fadeDuration = Duration(milliseconds: 100);
    int currentStep = 0;

    _fadeTimer = Timer.periodic(fadeDuration, (timer) async {
      currentStep++;
      double volume = 1.0 - (currentStep / fadeSteps);
      if (volume <= 0) {
        volume = 0;
        timer.cancel();
        await _violinPlayer.stop();
      }
      await _violinPlayer.setVolume(volume);
    });
  }

  void _closeTutorial() {
    setState(() {
      _showTutorial = false;
    });
  }

  Widget _buildTutorialContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final List<Map<String, dynamic>> tutorialPages = [
      {
        'icon': Icons.music_note,
        'title': 'Welcome to Violin Practice!',
        'text': 'This app helps you practice violin and makes it fun!',
      },
      {
        'icon': Icons.timer,
        'title': 'Choose Your Practice Time',
        'text': 'First, decide how long you want to practice.\nFor example: 30 minutes!',
      },
      {
        'icon': Icons.stars,
        'title': 'Earn Tokens & Points',
        'text': 'When you practice, you earn tokens and points!\nThe more you practice, the more you get!',
      },
      {
        'icon': Icons.videogame_asset,
        'title': 'Unlock Fun Games',
        'text': 'Reach milestones to unlock games that help with ear training and music theory!',
      },
      {
        'icon': Icons.card_giftcard,
        'title': 'Collect & Redeem',
        'text': 'After practicing, you can collect your tokens and redeem them for rewards!',
      },
      {
        'icon': Icons.play_arrow,
        'title': 'Ready to Start?',
        'text': 'Let\'s begin your musical journey!\nPress "Start" to meet your guide!',
      },
    ];

    final currentPage = tutorialPages[_tutorialPage];

    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          width: screenWidth * 0.85,
          padding: EdgeInsets.all(screenWidth * 0.06),
          decoration: BoxDecoration(
            color: const Color(0xFFDAA520),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFB22222), width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: const Color(0xFFB22222),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  currentPage['icon'] as IconData,
                  size: screenWidth * 0.15,
                  color: Colors.white,
                ),
              ),
              
              SizedBox(height: screenHeight * 0.03),
              
              // Title
              Text(
                currentPage['title'] as String,
                style: TextStyle(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFB22222),
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: screenHeight * 0.02),
              
              // Description
              Text(
                currentPage['text'] as String,
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: screenHeight * 0.04),
              
              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  tutorialPages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _tutorialPage ? 12 : 8,
                    height: index == _tutorialPage ? 12 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _tutorialPage
                          ? const Color(0xFFB22222)
                          : Colors.grey[400],
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: screenHeight * 0.03),
              
              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  if (_tutorialPage > 0)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _tutorialPage--;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.015,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_back, color: Color(0xFFB22222)),
                          const SizedBox(width: 5),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: const Color(0xFFB22222),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(width: 80),
                  
                  // Skip button
                  TextButton(
                    onPressed: _closeTutorial,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  
                  // Next/Done button
                  ElevatedButton(
                    onPressed: () {
                      if (_tutorialPage < tutorialPages.length - 1) {
                        setState(() {
                          _tutorialPage++;
                        });
                      } else {
                        _closeTutorial();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB22222),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.015,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _tutorialPage < tutorialPages.length - 1 ? 'Next' : 'Done',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          _tutorialPage < tutorialPages.length - 1
                              ? Icons.arrow_forward
                              : Icons.check,
                          color: Colors.white,
                          size: screenWidth * 0.05,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVideoInitialized || _isCheckingFirstTime) {
      return const Scaffold(
        backgroundColor: Color(0xFFDAA520),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFB22222),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      body: Stack(
        children: [
          // Video display
          Center(
            child: _isVideoInitialized
                ? FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : const CircularProgressIndicator(),
          ),
          
          // Skip button
          if (!_showTutorial)
            Positioned(
              top: 40,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const QuestSelectionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.fast_forward, size: 20),
                  ],
                ),
              ),
            ),
          
          // Start button overlay
          if (!_isPlaying && !_showTutorial)
            Container(
              color: Colors.black54,
              child: Center(
                child: ElevatedButton(
                  onPressed: _startSequence,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.play_arrow, size: 40),
                      SizedBox(width: 10),
                      Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Tutorial overlay
          if (_showTutorial)
            _buildTutorialContent(),
        ],
      ),
    );
  }
}