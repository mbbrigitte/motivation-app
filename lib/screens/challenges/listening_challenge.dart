import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_testapplication/services/storage_service.dart';
import '../practice_finished.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

class ListeningChallenge extends StatefulWidget {
  final bool isReplay;
  
  const ListeningChallenge({super.key, this.isReplay = false});

  @override
  State<ListeningChallenge> createState() => _ListeningChallengeState();
}

class _ListeningChallengeState extends State<ListeningChallenge> {
  int _currentTokens = 0;
  late VideoPlayerController _videoController;
  late AudioPlayer _audioPlayer;
  bool _isVideoInitialized = false;
  bool _isAudioPlaying = false;
  bool _hasPlayedAudio = false;
  bool _showCompletionMessage = false;

  @override
  void initState() {
    super.initState();
    _loadTokens();
    _initializeVideo();
    _initializeAudio();
    
    // Unlock this challenge when first accessed (not in replay mode)
    if (!widget.isReplay) {
      StorageService.unlockChallenge('listening_challenge');
    }
  }

  Future<void> _loadTokens() async {
    int tokens = await StorageService.loadTokens();
    setState(() {
      _currentTokens = tokens;
    });
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/violinist_lowerres.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController.setLooping(true);
        _videoController.play();
      }).catchError((error) {
        debugPrint('Error initializing video: $error');
      });
    
    // Listen for video position to stop looping after start button is clicked
    _videoController.addListener(() {
      if (_hasPlayedAudio && _videoController.value.position >= _videoController.value.duration) {
        _videoController.pause();
      }
    });
  }

  void _initializeAudio() {
    _audioPlayer = AudioPlayer();
    
    // Listen for when audio completes
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isAudioPlaying = false;
        _showCompletionMessage = true;
      });
      
      // Show completion dialog after a brief delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _showCompletionDialog();
        }
      });
    });
  }

  Future<void> _playAudio() async {
    if (_isAudioPlaying) return;
    
    setState(() {
      _isAudioPlaying = true;
      _hasPlayedAudio = true;
    });

    // Stop video looping
    _videoController.setLooping(false);

    try {
      await _audioPlayer.play(AssetSource('audio/Repeatafterme.m4a'));
    } catch (e) {
      debugPrint('Error playing audio: $e');
      setState(() {
        _isAudioPlaying = false;
      });
    }
  }

  Future<void> _showCompletionDialog() async {
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
                ? 'Well done! You trained your listening skills.'
                : 'Well done! You trained your listening skills.\n\nYou get one token!\nYou now have a total of $_currentTokens tokens!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 6));

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
    _videoController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: const Text('The Listening Challenge'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.02),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Text(
                  'The bird is singing some melodies. She wants you to repeat the same melodies after her. We will help you with that. Take your violin out and repeat after the bird! She will give you instructions.',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    color: const Color(0xFFB22222),
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              
              // Video Player - Smaller size
              Center(
                child: Container(
                  width: screenWidth * 0.6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red[900]!, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: _isVideoInitialized
                        ? AspectRatio(
                            aspectRatio: _videoController.value.aspectRatio,
                            child: VideoPlayer(_videoController),
                          )
                        : Container(
                            height: screenHeight * 0.25,
                            color: Colors.black,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              
              SizedBox(height: screenHeight * 0.04),
              
              // Play Audio Button
              ElevatedButton(
                onPressed: _isAudioPlaying ? null : _playAudio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: screenHeight * 0.02,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                  elevation: 5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAudioPlaying ? Icons.volume_up : Icons.play_arrow,
                      size: screenWidth * 0.07,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      _isAudioPlaying
                          ? 'Playing...'
                          : (_hasPlayedAudio ? 'Play Again' : 'Start Exercise'),
                      style: TextStyle(
                        fontSize: screenWidth * 0.048,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}