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

  bool _isInitialized = false;
  bool _isPlaying = false;
  Timer? _fadeTimer;
  Timer? _knightTimer;
  Timer? _endTimer;

  @override
  void initState() {
    super.initState();
    _initializeAndAutoPlay();
  }

  Future<void> _initializeAndAutoPlay() async {
    // Initialize video
    _videoController = VideoPlayerController.asset('assets/videos/dragon_on_chest.mp4');
    await _videoController.initialize();
    await _videoController.setLooping(false);

    // Seek to 500ms and pause (like TreasureChest)
    await _videoController.seekTo(const Duration(milliseconds: 500));
    await _videoController.pause();

    // Add listener before playing
    _videoController.addListener(_videoListener);

    setState(() {
      _isInitialized = true;
    });

    // Small delay to ensure everything is ready, then auto-start
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted) {
      _startSequence();
    }
  }

  void _videoListener() {
    if (_videoController.value.position >= _videoController.value.duration &&
        _isPlaying) {
      setState(() => _isPlaying = false);
      _videoController.pause();
    }
    // Force UI update during playback
    if (mounted && _isPlaying) {
      setState(() {});
    }
  }

  void _startSequence() async {
    if (!_videoController.value.isInitialized || _isPlaying) return;

    setState(() {
      _isPlaying = true;
    });

    // Seek to beginning and play
    await _videoController.seekTo(Duration.zero);
    await _videoController.play();

    // Start violin audio
    await _violinPlayer.play(AssetSource('audio/intro1.mp3'));
    await _violinPlayer.seek(const Duration(seconds: 2));
    await _violinPlayer.setVolume(1.0);

    // Play knight audio after 7 seconds and fade violin
    _knightTimer = Timer(const Duration(seconds: 7), () async {
      if (mounted) {
        await _knightPlayer.play(AssetSource('audio/Audio_knight.m4a'));
        _startViolinFade();
      }
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

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
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
          // Video background
          Center(
            child: _videoController.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController),
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
        ],
      ),
    );
  }
}