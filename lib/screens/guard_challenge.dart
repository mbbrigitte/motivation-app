import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../services/storage_service.dart';
import 'practice_finished.dart';

class GuardChallenge extends StatefulWidget {
  const GuardChallenge({super.key});

  @override
  State<GuardChallenge> createState() => _GuardChallengeState();
}

class _GuardChallengeState extends State<GuardChallenge> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _buttonPressed = false;
  int _currentPoints = 0;
  Timer? _loopTimer;

  @override
  void initState() {
    super.initState();
    _loadPoints();
    _initializeVideo();
  }

  Future<void> _loadPoints() async {
    int points = await StorageService.loadPoints();
    setState(() {
      _currentPoints = points;
    });
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset(
      'assets/videos/Guard_challenge.mp4',
    );

    await _videoController.initialize();

    await _videoController.setLooping(false);

    // Start at beginning and play first second on loop
    await _videoController.seekTo(Duration.zero);
    await _videoController.play();

    _videoController.addListener(_videoListener);

    // Loop first second
    _loopTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_isPlaying &&
          _videoController.value.position >= const Duration(seconds: 1)) {
        _videoController.seekTo(Duration.zero);
      }
    });

    setState(() => _isVideoInitialized = true);
  }

  void _videoListener() {
    // Loop first second until button is pressed
    if (!_isPlaying &&
        _videoController.value.position >= const Duration(seconds: 1)) {
      _videoController.seekTo(Duration.zero);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _stopLooping() async {
    _loopTimer?.cancel();
    _videoController.removeListener(_videoListener);
  }

  Future<void> _onPlayedQuietly() async {
    if (_buttonPressed) return;

    setState(() {
      _buttonPressed = true;
      _isPlaying = true;  // FIX
    });

    await _stopLooping();

    // Add point + token
    await _addPointAndToken();

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
            'Well done! The guard is still sleeping!\nYou get an extra point!\nYou now have a total of $_currentPoints points!',
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PracticeFinished()),
        );
      }
    }
  }

  Future<void> _onPlayedLoud() async {
    if (_buttonPressed) return;

    setState(() {
      _buttonPressed = true;
      _isPlaying = true;  // FIX
    });

    await _stopLooping();

    // Play video from beginning
    await _videoController.seekTo(Duration.zero);
    await _videoController.play();

  // Wait until video actually reaches 7.8 seconds
     while (_videoController.value.position <
      const Duration(milliseconds: 7800)) {
     await Future.delayed(const Duration(milliseconds: 50));
     }

  // Stop BEFORE it reaches the end
  await _videoController.pause();

  // Seek to the exact frame you want
  await _videoController.seekTo(const Duration(milliseconds: 8000));

  // Force-render that frame
  setState(() {});


    // WAIT 4 seconds at the final frame
    await Future.delayed(const Duration(seconds: 4));

    // Add point & token
    await _addPointAndToken();

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
            'The guard woke up but was happy!\nYou get an extra point!\nYou now have a total of $_currentPoints points!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 5));

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PracticeFinished()),
        );
      }
    }
  }

  Future<void> _addPointAndToken() async {
    int currentTokens = await StorageService.loadTokens();
    await StorageService.saveTokens(currentTokens + 1);

    int totalTokens = await StorageService.loadTotalTokens();
    await StorageService.saveTotalTokens(totalTokens + 1);

    await StorageService.addPoints(1);
    int updatedPoints = await StorageService.loadPoints();

    setState(() {
      _currentPoints = updatedPoints;
    });
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVideoInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFDAA520),
        appBar: AppBar(
          title: const Text('The Guard Challenge'),
          backgroundColor: Colors.red[900],
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: const Text('The Guard Challenge'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Text(
                'Oh no, a sleeping guard!\nPlay one of your old violin songs very quietly.\nMake sure the guard does not wake up!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB22222),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              if (!_buttonPressed) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onPlayedQuietly,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                    ),
                    child: const Text(
                      'I played very quietly!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onPlayedLoud,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                    ),
                    child: const Text(
                      'I played quite loud!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
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
}
