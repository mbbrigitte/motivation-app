import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_testapplication/services/storage_service.dart';
import '../practice_finished.dart';

class AnimalChallenge extends StatefulWidget {
  final bool isReplay;
  
  const AnimalChallenge({super.key, this.isReplay = false});

  @override
  State<AnimalChallenge> createState() => _AnimalChallengeState();
}

class _AnimalChallengeState extends State<AnimalChallenge> with TickerProviderStateMixin {
  int _currentTokens = 0;
  bool _showIntro = true;
  bool _isSpinning = false;
  bool _hasSpunWheel = false;
  bool _hasFinishedPlaying = false;
  String _selectedAnimal = '';
  
  late AnimationController _spinController;
  double _currentRotation = 0;
  double _targetRotation = 0;
  
  // Animal names in clockwise order starting from 12 o'clock (0 degrees)
  final List<String> _animals = [
    'Tiger',
    'Mouse', 
    'Crocodile',
    'Horse',
    'Elephant',
    'Lion',
  ];
  
  // Map animals to their image files
  final Map<String, String> _animalImages = {
    'Tiger': 'tiger.webp',
    'Mouse': 'mouse.webp',
    'Crocodile': 'croc.webp',
    'Horse': 'horse.jpeg',
    'Elephant': 'elephant.webp',
    'Lion': 'Lion-removebg-preview.webp',
  };

  @override
  void initState() {
    super.initState();
    _loadTokens();
    
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    
    // Unlock this challenge when first accessed (not in replay mode)
    if (!widget.isReplay) {
      StorageService.unlockChallenge('animal_challenge');
    }
  }

  Future<void> _loadTokens() async {
    int tokens = await StorageService.loadTokens();
    setState(() {
      _currentTokens = tokens;
    });
  }

  void _goToWheel() {
    setState(() {
      _showIntro = false;
    });
  }

  void _startSpinning() {
    if (_isSpinning || _hasSpunWheel) return;
    
    setState(() {
      _isSpinning = true;
    });
    
    // Start continuous spinning
    _spinController.repeat();
  }

  void _stopSpinning() async {
    if (!_isSpinning || _hasSpunWheel) return;
    
    // Get current rotation from the spinning animation
    final currentValue = _spinController.value;
    _currentRotation = currentValue * 2 * math.pi;
    
    // Stop the repeat animation
    _spinController.stop();
    _spinController.reset();
    
    // Mark that we're no longer in fast spinning mode
    setState(() {
      _isSpinning = false;
    });
    
    // Generate random final position - add 2-4 more rotations from current position
    final random = math.Random();
    final extraRotations = 2 + random.nextInt(3);
    final randomAngle = random.nextDouble() * 2 * math.pi;
    _targetRotation = _currentRotation + (extraRotations * 2 * math.pi) + randomAngle;
    
    // Animate to final position with slow deceleration
    final Animation<double> animation = Tween<double>(
      begin: _currentRotation,
      end: _targetRotation,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOut, // Changed to easeOut for smoother deceleration
    ));
    
    _spinController.duration = const Duration(milliseconds: 4000); // Longer duration for smoother slowdown
    
    animation.addListener(() {
      setState(() {
        _currentRotation = animation.value;
      });
    });
    
    // Start the slowdown animation
    await _spinController.forward(from: 0);
    
    // Add shiver effect
    await _shiverAnimation();
    
    // Calculate which animal was selected
    _determineSelectedAnimal();
    
    setState(() {
      _hasSpunWheel = true;
    });
    
    // Wait 3 seconds before showing the result screen
    await Future.delayed(const Duration(seconds: 3));
  }

  Future<void> _shiverAnimation() async {
    const shiverAmount = 0.05;
    const shiverCount = 4;
    
    for (int i = 0; i < shiverCount; i++) {
      setState(() {
        _currentRotation += shiverAmount;
      });
      await Future.delayed(const Duration(milliseconds: 50));
      
      setState(() {
        _currentRotation -= shiverAmount;
      });
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _determineSelectedAnimal() {
    // The indicator is at 3 o'clock (pointing to the right)
    // Normalize the final rotation to 0-2π range
    final normalizedRotation = _currentRotation % (2 * math.pi);
    
    // The wheel rotates clockwise, and we need to find which animal is at the 3 o'clock position
    // Since the indicator points right (90 degrees from top), we need to figure out
    // which animal segment is at that position
    
    // Calculate the effective angle: the indicator is at 90 degrees (π/2),
    // so we need to see which animal is there after the wheel has rotated
    // We subtract the wheel rotation from the indicator position
    double effectiveAngle = (math.pi / 2 - normalizedRotation) % (2 * math.pi);
    if (effectiveAngle < 0) effectiveAngle += 2 * math.pi;
    
    // Each animal occupies 60 degrees (π/3 radians)
    final segmentSize = (2 * math.pi) / 6;
    
    // Find which segment (0-5) the effective angle falls into
    int animalIndex = (effectiveAngle / segmentSize).floor();
    
    // Debug print to help verify
    print('Final rotation: $_currentRotation radians (${_currentRotation * 180 / math.pi} degrees)');
    print('Normalized: $normalizedRotation radians (${normalizedRotation * 180 / math.pi} degrees)');
    print('Effective angle: $effectiveAngle radians (${effectiveAngle * 180 / math.pi} degrees)');
    print('Animal index: $animalIndex');
    print('Selected animal: ${_animals[animalIndex % 6]}');
    
    setState(() {
      _selectedAnimal = _animals[animalIndex % 6];
    });
  }

  Future<void> _onFinishedPlaying() async {
    setState(() {
      _hasFinishedPlaying = true;
    });
    
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
                ? 'Well done! You earned an extra point!'
                : 'Well done! You earned an extra point!\n\nYou now have a total of $_currentTokens tokens!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 3));

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
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final wheelSize = screenWidth * 0.75 > 350 ? 350.0 : screenWidth * 0.75;
    final indicatorSize = wheelSize * 0.24;
    
    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: Text(
          'The Animal Challenge',
          style: TextStyle(fontSize: screenWidth * 0.045),
        ),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.06),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.02),
                
                // Introduction screen
                if (_showIntro) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Text(
                      'Oh, a girl is playing the violin loud and confident like a tiger.',
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
                  
                  SizedBox(height: screenHeight * 0.025),
                  
                  Image.asset(
                    'assets/images/girl_tiger_violin.webp',
                    width: screenWidth * 0.85,
                    height: screenWidth * 0.85,
                    fit: BoxFit.contain,
                  ),
                  
                  SizedBox(height: screenHeight * 0.025),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Text(
                      'Can you also play one of your pieces like an animal? The animal spinning wheel will help you choose the animal.',
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
                  
                  ElevatedButton(
                    onPressed: _goToWheel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[900],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.1,
                        vertical: screenHeight * 0.025,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(color: Colors.white, width: 3),
                      ),
                    ),
                    child: Text(
                      'Go to wheel',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]
                else if (!_hasSpunWheel) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Text(
                      'Spin the wheel',
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
                  
                  SizedBox(height: screenHeight * 0.04),
                  
                  SizedBox(
                    height: wheelSize + 50,
                    width: wheelSize + 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _spinController,
                          builder: (context, child) {
                            final rotation = _isSpinning 
                                ? _spinController.value * 2 * math.pi 
                                : _currentRotation;
                            
                            return Transform.rotate(
                              angle: rotation,
                              child: Image.asset(
                                'assets/images/spinning_part_of_wheel.webp',
                                width: wheelSize,
                                height: wheelSize,
                                fit: BoxFit.contain,
                              ),
                            );
                          },
                        ),
                        
                        Image.asset(
                          'assets/images/rim_part_of_wheel.webp',
                          width: wheelSize,
                          height: wheelSize,
                          fit: BoxFit.contain,
                        ),
                        
                        Positioned(
                          right: 0,
                          child: Transform.rotate(
                            angle: math.pi / 2,
                            child: Image.asset(
                              'assets/images/indicator_part_of_wheel.webp',
                              width: indicatorSize,
                              height: indicatorSize,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.04),
                  
                  ElevatedButton(
                    onPressed: _isSpinning ? _stopSpinning : _startSpinning,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[900],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.1,
                        vertical: screenHeight * 0.025,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(color: Colors.white, width: 3),
                      ),
                    ),
                    child: Text(
                      _isSpinning ? 'Stop' : 'Turn',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]
                else if (_hasSpunWheel && !_hasFinishedPlaying) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Text(
                      'Oh, it is ${_selectedAnimal.toLowerCase() == 'elephant' ? 'an' : 'a'} $_selectedAnimal!',
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
                  
                  SizedBox(height: screenHeight * 0.02),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Text(
                      'Now take your violin and play one of your old pieces to sound like ${_selectedAnimal.toLowerCase() == 'elephant' ? 'an' : 'a'} $_selectedAnimal!',
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
                  
                  Image.asset(
                    'assets/images/${_animalImages[_selectedAnimal]}',
                    width: screenWidth * 0.6,
                    height: screenWidth * 0.6,
                    fit: BoxFit.contain,
                  ),
                  
                  SizedBox(height: screenHeight * 0.04),
                  
                  ElevatedButton(
                    onPressed: _onFinishedPlaying,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.08,
                        vertical: screenHeight * 0.025,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(color: Colors.white, width: 3),
                      ),
                    ),
                    child: Text(
                      'I finished playing like ${_selectedAnimal.toLowerCase() == 'elephant' ? 'an' : 'a'} $_selectedAnimal',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}