import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/storage_service.dart';

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
  String selectedCharacter = 'knight';

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  Future<void> _initializeMedia() async {
    // Load selected character
    selectedCharacter = await StorageService.loadSelectedCharacter();
    
    // Determine which video to play based on character
    String videoPath = selectedCharacter.toLowerCase() == 'gerbil'
        ? 'assets/videos/Gerbil_dance1.mp4'
        : 'assets/videos/Happy_dance.mp4';
    
    // Initialize and configure audio player for Android compatibility
    _audioPlayer = AudioPlayer();
    
    try {
      // CRITICAL: Use AudioFocus.none to NOT steal focus from video
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
            audioFocus: AndroidAudioFocus.none, // Don't steal focus from video!
          ),
        ),
      );
    } catch (e) {
      print('Error configuring audio player: $e');
    }
    
    // Initialize video
    _videoController = VideoPlayerController.asset(videoPath);
    await _videoController.initialize();
    
    // Add listener to pause video 0.5 seconds before the end
    _videoController.addListener(_videoListener);
    
    // Start video first
    await _videoController.play();
    
    // CRITICAL: Add delay before starting audio to prevent Android media session conflict
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Start audio after video has established its audio session
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

  void _closeApp() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[700],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white, width: 3),
        ),
        title: const Text(
          'Close App?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Are you sure you want to exit?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Close the app
                  SystemNavigator.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Exit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
              
              // Two buttons side by side
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back to Start button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton(
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
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Back to Start',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  
                  // Close App button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ElevatedButton(
                        onPressed: _closeApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Close App',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
}