// ========== exit_screen.dart ==========
// Create this as a new file: lib/screens/exit_screen.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

class ExitScreen extends StatefulWidget {
  const ExitScreen({super.key});

  @override
  State<ExitScreen> createState() => _ExitScreenState();
}

class _ExitScreenState extends State<ExitScreen> {
  late VideoPlayerController _videoController;
  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;
  double _currentVolume = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  Future<void> _initializeMedia() async {
    // Initialize video
    _videoController = VideoPlayerController.asset('assets/videos/Happy_dance.mp4');
    await _videoController.initialize();
    
    // Add listener to pause video 0.5 seconds before the end
    _videoController.addListener(_videoListener);
    
    // Initialize audio
    _audioPlayer = AudioPlayer();
    await _audioPlayer.setAudioContext(
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
    // Start both video and audio
    await _videoController.play();
    await _audioPlayer.play(AssetSource('audio/ENo_5.mp3'));
    
    setState(() {
      _isInitialized = true;
    });

    // Start listening for fade out timing
    _startFadeOutTimer();
  }

  void _videoListener() {
    if (!_videoController.value.isInitialized) return;
    
    final duration = _videoController.value.duration;
    final position = _videoController.value.position;
    final remaining = duration - position;
    
    // Pause 0.5 seconds before the end
    if (remaining <= const Duration(milliseconds: 500) && 
        remaining > Duration.zero && 
        _videoController.value.isPlaying) {
      _videoController.pause();
    }
  }

  void _startFadeOutTimer() async {
    // Wait 6 seconds before starting fade
    await Future.delayed(const Duration(seconds: 6));
    
    // Fade out over 3 seconds (from 6s to 9s)
    const fadeDuration = 3000; // milliseconds
    const fadeSteps = 30; // number of steps for smooth fade
    const stepDuration = fadeDuration ~/ fadeSteps;
    
    for (int i = 0; i < fadeSteps; i++) {
      if (!mounted) break;
      
      _currentVolume = 1.0 - (i / fadeSteps);
      await _audioPlayer.setVolume(_currentVolume);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }
    
    // Stop audio at 9 seconds
    await _audioPlayer.stop();
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[800],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display the Happy_dance.mp4 video
              Expanded(
                child: _isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: VideoPlayer(_videoController),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
              ),
              
              const SizedBox(height: 40),
              
              // Optional: Add a button to return to home
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Back to Start',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}