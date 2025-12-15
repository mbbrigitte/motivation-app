import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
//import '../../services/storage_service.dart';
import 'package:flutter_testapplication/services/storage_service.dart';
import '../practice_finished.dart';

class GuardChallenge extends StatefulWidget {
  final bool isReplay;
  
  const GuardChallenge({super.key, this.isReplay = false});

  @override
  State<GuardChallenge> createState() => _GuardChallengeState();
}

class _GuardChallengeState extends State<GuardChallenge> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _buttonPressed = false;
  int _currentTokens = 0;
  Timer? _loopTimer;

  @override
  void initState() {
    super.initState();
    _loadTokens();
    _initializeVideo();
    
    // Unlock this challenge when first accessed (not in replay mode)
    if (!widget.isReplay) {
      StorageService.unlockChallenge('guard_challenge');
    }
  }

  Future<void> _loadTokens() async {
    int tokens = await StorageService.loadTokens();
    setState(() {
      _currentTokens = tokens;
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
      _isPlaying = true;
    });

    await _stopLooping();

    // Only award tokens if not in replay mode
    if (!widget.isReplay) {
      await _addToken();
    }

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
            widget.isReplay
                ? 'Well done! The guard is still sleeping!'
                : 'Well done! The guard is still sleeping!\nYou get one token!\nYou now have a total of $_currentTokens tokens!',
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
          Navigator.of(context).pop(); // Go back to challenges list
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PracticeFinished()),
          );
        }
      }
    }
  }

  Future<void> _onPlayedLoud() async {
    if (_buttonPressed) return;

    setState(() {
      _buttonPressed = true;
      _isPlaying = true;
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

    // WAIT 6 seconds at the final frame
    await Future.delayed(const Duration(seconds: 6));

    // Only award tokens if not in replay mode
    if (!widget.isReplay) {
      await _addToken();
    }

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
            widget.isReplay
                ? 'The guard woke up but was happy!'
                : 'The guard woke up but was happy!\nYou get one token!\nYou now have a total of $_currentTokens tokens!',
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
          Navigator.of(context).pop(); // Go back to challenges list
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