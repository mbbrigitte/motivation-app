// screens/goal_reached.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math';
import 'practice_finished.dart';

class GoalReached extends StatefulWidget {
  const GoalReached({super.key});

  @override
  State<GoalReached> createState() => _GoalReachedState();
}

class _GoalReachedState extends State<GoalReached> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  final AudioPlayer _audioPlayer1 = AudioPlayer();
  final AudioPlayer _audioPlayer2 = AudioPlayer();

  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _showConfetti = false;
  
  List<ConfettiParticle> _confettiParticles = [];
  late AnimationController _confettiController;
  Timer? _confettiTimer;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayers();
    _initializeVideo();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
  }

  Future<void> _initializeAudioPlayers() async {
    try {
      await _audioPlayer1.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: [AVAudioSessionOptions.mixWithOthers],
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

      await _audioPlayer2.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: [AVAudioSessionOptions.mixWithOthers],
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
      'assets/videos/newking_lowest.mp4',
    );

    await _videoController.initialize();
    await _videoController.setLooping(false);
    await _videoController.pause();

    _videoController.addListener(_videoListener);

    setState(() => _isVideoInitialized = true);

    // Auto-start the sequence
    _startSequence();
  }

  void _videoListener() {
    final value = _videoController.value;

    if (_isPlaying &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      setState(() => _isPlaying = false);
      _onVideoComplete();
    }
  }

  Future<void> _startSequence() async {
    if (_isVideoInitialized && !_isPlaying) {
      setState(() => _isPlaying = true);

      _videoController.removeListener(_videoListener);
      await _videoController.seekTo(Duration.zero);
      await Future.delayed(const Duration(milliseconds: 100));
      _videoController.addListener(_videoListener);

      await _videoController.play();

      // Play first audio after video starts
      await Future.delayed(const Duration(milliseconds: 300));
      await _audioPlayer1.play(AssetSource('audio/Knight_part1.m4a'));

      // Play second audio at 9 seconds
      Timer(const Duration(seconds: 9), () async {
        await _audioPlayer2.play(AssetSource('audio/Knight_part2.m4a'));
      });
    }
  }

  Future<void> _onVideoComplete() async {
    // Pause for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    // Start confetti
    _startConfetti();

    // After 8 seconds of confetti, navigate away
    await Future.delayed(const Duration(seconds: 10));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PracticeFinished()),
      );
    }
  }

  void _startConfetti() {
    setState(() {
      _showConfetti = true;
      _confettiParticles = List.generate(135, (index) {
        final random = Random();
        return ConfettiParticle(
          x: random.nextDouble(),
          y: -0.1,
          color: _getRandomConfettiColor(random),
          size: 8 + random.nextDouble() * 8,
          speedY: 0.3 + random.nextDouble() * 0.5,
          speedX: (random.nextDouble() - 0.5) * 0.3,
          rotation: random.nextDouble() * 2 * pi,
          rotationSpeed: (random.nextDouble() - 0.5) * 0.2,
        );
      });
    });

    _confettiController.forward();

    // Animate confetti falling
    _confettiTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          for (var particle in _confettiParticles) {
            particle.y += particle.speedY * 0.03;
            particle.x += particle.speedX * 0.03;
            particle.rotation += particle.rotationSpeed;
          }
        });
      }
    });
  }

  Color _getRandomConfettiColor(Random random) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    _audioPlayer1.dispose();
    _audioPlayer2.dispose();
    _confettiController.dispose();
    _confettiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
      appBar: AppBar(
        title: const Text('Welcome to the Castle'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Video player - big and centered
          Center(
            child: Container(
              width: screenWidth * 0.9,
              height: screenHeight * 0.7,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              ),
            ),
          ),

          // Confetti overlay
          if (_showConfetti)
            IgnorePointer(
              child: CustomPaint(
                size: Size(screenWidth, screenHeight),
                painter: ConfettiPainter(_confettiParticles),
              ),
            ),

          // Celebration text during confetti
          if (_showConfetti)
            Positioned(
              left: screenWidth * 0.1,
              right: screenWidth * 0.1,
              bottom: screenHeight * 0.1,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenHeight * 0.025,
                ),
                decoration: BoxDecoration(
                  color: Colors.yellow[600],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red[900]!, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  '🎉 Congratulations! 🎉',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.08).clamp(24.0, 48.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ConfettiParticle {
  double x;
  double y;
  Color color;
  double size;
  double speedY;
  double speedX;
  double rotation;
  double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      final centerX = particle.x * size.width;
      final centerY = particle.y * size.height;

      canvas.save();
      canvas.translate(centerX, centerY);
      canvas.rotate(particle.rotation);

      // Draw confetti as small rectangles
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size / 2,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}