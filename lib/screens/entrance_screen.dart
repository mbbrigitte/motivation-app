import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'quest_selection_screen.dart';

class EntranceScreen extends StatefulWidget {
  const EntranceScreen({super.key});

  @override
  State<EntranceScreen> createState() => _EntranceScreenState();
}

class _EntranceScreenState extends State<EntranceScreen> {
  late VideoPlayerController _videoController;
  final AudioPlayer _violinPlayer = AudioPlayer();
  final AudioPlayer _knightPlayer = AudioPlayer();

  bool _isVideoInitialized = false; // Changed to match TreasureChest naming
  bool _isPlaying = false;
  Timer? _fadeTimer;
  Timer? _knightTimer;
  Timer? _endTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo(); // Changed method name to match TreasureChest
  }

  // EXACT SAME pattern as TreasureChest
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

  // EXACT SAME listener pattern as TreasureChest
  void _videoListener() {
    final value = _videoController.value;

   if (_isPlaying &&
      value.duration > Duration.zero &&   // Prevent invalid state
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

  // This is like _collectTokens in TreasureChest - triggers video playback
void _startSequence() async {
  if (_isVideoInitialized && !_isPlaying) {
    setState(() => _isPlaying = true);

    _videoController.removeListener(_videoListener); // remove early listener
    await _videoController.seekTo(Duration.zero);

    // delay to avoid Android returning position==duration
    await Future.delayed(const Duration(milliseconds: 100));
    _videoController.addListener(_videoListener);

    await _videoController.play();
  }


    // Start violin audio
    await _violinPlayer.play(AssetSource('audio/intro1.mp3'));
    await _violinPlayer.seek(const Duration(seconds: 2));
    await _violinPlayer.setVolume(1.0);

    // Play knight audio after 7 seconds and fade violin
    _knightTimer = Timer(const Duration(seconds: 7), () async {
      await _knightPlayer.play(AssetSource('audio/Audio_knight.m4a'));
      _startViolinFade();
    });

    // Navigate to quest selection after 18 seconds
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

  @override
  Widget build(BuildContext context) {
    if (!_isVideoInitialized) {
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
          // 🎯 CRITICAL: Use EXACT SAME video display pattern as TreasureChest
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
          if (!_isPlaying)
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
        ],
      ),
    );
  }
}