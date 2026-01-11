import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_testapplication/services/storage_service.dart';
import '../practice_finished.dart';

class BirdNoteGame extends StatefulWidget {
  final bool isReplay;
  
  BirdNoteGame({super.key, this.isReplay = false});

  @override
  State<BirdNoteGame> createState() => _BirdNoteGameState();
}

class _BirdNoteGameState extends State<BirdNoteGame> with TickerProviderStateMixin {
  // Game state
  int _currentLevel = 0; // 0=A, 1=C, 2=F, 3=D
  int _correctCatches = 0;
  int _currentTokens = 0;
  
  // Basket position
  double _basketX = 0.5; // 0 to 1 (percentage of screen width)
  
  // Bird state
  double _birdX = 0.0;
  double _birdY = 0.35; // 50-20% from top = 20-50% as fraction
  bool _birdMovingRight = true;
  double _birdSpeed = 0.003;
  
  // Falling notes
  List<FallingNote> _fallingNotes = [];
  
  // Timers
  Timer? _gameTimer;
  Timer? _birdTimer;
  Timer? _dropTimer;
  
  // Accelerometer
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Flash effect
  bool _showFlash = false;
  Color _flashColor = Colors.green;
  
  // Level configuration
  final List<Map<String, dynamic>> _levels = [
    {'letter': 'A', 'basket': 'assets/images/Basket_A.webp', 'correctNote': 'noteA.png', 'correctNotes': ['noteA.png']},
    {'letter': 'C', 'basket': 'assets/images/Basket_C.webp', 'correctNote': 'noteC.png', 'correctNotes': ['noteC.png']},
    {'letter': 'F', 'basket': 'assets/images/Basket_F.webp', 'correctNote': 'noteF.png', 'correctNotes': ['noteF.png']},
    {'letter': 'D', 'basket': 'assets/images/Basket_D.webp', 'correctNote': 'noteD.png', 'correctNotes': ['noteD.png', 'noteD2.png']},
  ];
  
  final List<String> _allNotes = ['noteA.png', 'noteC.png', 'noteD.png', 'noteD2.png', 'noteE.png', 'noteF.png'];
  final Random _random = Random();
  
  bool _showMessage = true;
  bool _gameComplete = false;
  bool _isAndroid = false;

  @override
  void initState() {
    super.initState();
    _checkPlatform();
    _loadTokens();
    _startGame();
    
    // Unlock this challenge when first accessed (not in replay mode)
    if (!widget.isReplay) {
      StorageService.unlockChallenge('notes_challenge');
    }
  }

  void _checkPlatform() {
    // Check if running on Android
    if (!kIsWeb) {
      try {
        _isAndroid = Platform.isAndroid;
      } catch (e) {
        _isAndroid = false;
      }
    }
  }

  Future<void> _loadTokens() async {
    int tokens = await StorageService.loadTokens();
    setState(() {
      _currentTokens = tokens;
    });
  }

  void _startGame() {
    // Show initial message
    _showLevelMessage();
    
    // Start accelerometer
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (!_gameComplete) {
        setState(() {
          // Use x-axis tilt to move basket (tilt left = negative, tilt right = positive)
          _basketX = (_basketX - event.x * 0.01).clamp(0.0, 1.0);
        });
      }
    });
    
    // Start bird movement
    _birdTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_gameComplete) {
        _updateBird();
      }
    });
    
    // Start note dropping
    _dropTimer = Timer.periodic(Duration(milliseconds: 1500 + _random.nextInt(1000)), (timer) {
      if (!_gameComplete && !_showMessage) {
        _dropNote();
      }
    });
    
    // Start game update loop
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_gameComplete) {
        _updateGame();
      }
    });
  }

  void _showLevelMessage() {
    setState(() {
      _showMessage = true;
    });
    
    String message = '';
    if (_currentLevel == 0) {
      if (_isAndroid) {
        message = 'Tilt your phone left and right to move the basket.\n\nCatch all the A-notes.\nAvoid the other notes!';
      } else {
        message = 'Catch all the A-notes.\nAvoid the other notes!';
      }
    } else {
      String letter = _levels[_currentLevel]['letter'];
      message = 'Now catch the ${letter}s!';
    }
    
    // Auto-hide message after appropriate time
    int displaySeconds = (_currentLevel == 0 && _isAndroid) ? 5 : 3;
    Future.delayed(Duration(seconds: displaySeconds), () {
      if (mounted) {
        setState(() {
          _showMessage = false;
        });
      }
    });
  }

  void _updateBird() {
    setState(() {
      if (_birdMovingRight) {
        _birdX += _birdSpeed;
        if (_birdX >= 1.0) {
          _birdX = 1.0;
          _birdMovingRight = false;
        }
      } else {
        _birdX -= _birdSpeed;
        if (_birdX <= 0.0) {
          _birdX = 0.0;
          _birdMovingRight = true;
        }
      }
      
      // Randomly adjust Y position between 20% and 50%
      if (_random.nextDouble() < 0.01) {
        _birdY = 0.2 + _random.nextDouble() * 0.3;
      }
    });
  }

  void _dropNote() {
    String randomNote;
    
    // 40% chance to drop the correct note for current level
    if (_random.nextDouble() < 0.4) {
      List<String> correctNotes = _levels[_currentLevel]['correctNotes'];
      randomNote = correctNotes[_random.nextInt(correctNotes.length)];
    } else {
      // Drop a random note (might still be correct by chance)
      randomNote = _allNotes[_random.nextInt(_allNotes.length)];
    }
    
    setState(() {
      _fallingNotes.add(FallingNote(
        note: randomNote,
        x: _birdX,
        y: _birdY,
      ));
    });
  }

  void _updateGame() {
    if (_fallingNotes.isEmpty) return;
    
    List<FallingNote> notesToRemove = [];
    
    setState(() {
      for (var note in _fallingNotes) {
        note.y += 0.005; // Fall speed
        
        // Check if note reached bottom
        if (note.y >= 1.0) {
          notesToRemove.add(note);
        }
        
        // Check collision with basket - adjusted for larger basket
        else if (note.y >= 0.78 && note.y <= 0.95) {
          double basketLeft = _basketX - 0.18;  // Increased for 2x basket
          double basketRight = _basketX + 0.18;  // Increased for 2x basket
          
          if (note.x >= basketLeft && note.x <= basketRight) {
            notesToRemove.add(note);
            _checkNoteCatch(note.note);
          }
        }
      }
      
      _fallingNotes.removeWhere((note) => notesToRemove.contains(note));
    });
  }

  void _checkNoteCatch(String caughtNote) {
    List<String> correctNotes = _levels[_currentLevel]['correctNotes'];
    bool isCorrect = correctNotes.contains(caughtNote);
    
    if (isCorrect) {
      // Correct note caught
      _playSound('bing');
      _showFlashEffect(Colors.green);
      
      setState(() {
        _correctCatches++;
      });
      
      if (_correctCatches >= 5) {
        _levelComplete();
      }
    } else {
      // Wrong note caught
      _playSound('baaah');
      _showFlashEffect(Colors.red);
    }
  }

  void _playSound(String sound) {
    // Play sound effect
    if (sound == 'bing') {
      _audioPlayer.play(AssetSource('audio/correct.mp3'));
    } else {
      _audioPlayer.play(AssetSource('audio/wrong.mp3'));
    }
  }

  void _showFlashEffect(Color color) {
    setState(() {
      _showFlash = true;
      _flashColor = color;
    });
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _showFlash = false;
        });
      }
    });
  }

  void _levelComplete() {
    if (_currentLevel < 3) {
      // Move to next level
      String letter = _levels[_currentLevel]['letter'];
      
      setState(() {
        _currentLevel++;
        _correctCatches = 0;
        _showMessage = true;
      });
      
      // Show congratulations message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.green[700]!,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.yellow[600]!, width: 3),
          ),
          content: Text(
            'Well done, you caught 5 ${letter}s!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
          _showLevelMessage();
        }
      });
    } else {
      // Game complete
      _gameComplete = true;
      _onGameComplete();
    }
  }

  Future<void> _onGameComplete() async {
    // Cancel all timers
    _gameTimer?.cancel();
    _birdTimer?.cancel();
    _dropTimer?.cancel();
    _accelerometerSubscription?.cancel();
    
    // Only award tokens if not in replay mode
    if (!widget.isReplay) {
      await _addToken();
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.yellow[600]!,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.red[900]!, width: 3),
          ),
          content: Text(
            widget.isReplay
                ? 'You know your music notes already quite well. Good job!'
                : 'You know your music notes already quite well. Good job!\n\nYou get an extra token!\nYou now have a total of $_currentTokens tokens!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[900],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 4));

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
    _gameTimer?.cancel();
    _birdTimer?.cancel();
    _dropTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            setState(() {
              _basketX = (_basketX - 0.05).clamp(0.0, 1.0);
            });
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            setState(() {
              _basketX = (_basketX + 0.05).clamp(0.0, 1.0);
            });
          }
        }
      },
      child: Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background_for_bird.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Flash effect
          if (_showFlash)
            Container(
              color: _flashColor.withOpacity(0.3),
            ),
          
          // Bird - MADE 20% BIGGER (144 instead of 120)
          Positioned(
            left: _birdX * size.width - 72,
            top: _birdY * size.height,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..scale(_birdMovingRight ? -1.0 : 1.0, 1.0),
              child: Image.asset(
                'assets/images/bird.webp',
                width: 144,
                height: 144,
              ),
            ),
          ),
          
          // Falling notes - MADE BIGGER (100 instead of 70)
          ..._fallingNotes.map((note) => Positioned(
            left: note.x * size.width - (50 * size.width / 400),
            top: note.y * size.height,
            child: Image.asset(
              'assets/images/${note.note}',
              width: 100 * size.width / 400,
              height: 100 * size.width / 400,
            ),
          )).toList(),
          
          // Basket - MADE 2X BIGGER (180 instead of 90)
          Positioned(
            left: _basketX * size.width - (90 * size.width / 400),
            bottom: 20 * size.height / 800,
            child: Image.asset(
              _levels[_currentLevel]['basket'],
              width: 180 * size.width / 400,
              height: 180 * size.width / 400,
            ),
          ),
          
          // Score indicator
          Positioned(
            top: 50 * size.height / 800,
            left: 20 * size.width / 400,
            child: Container(
              padding: EdgeInsets.all(12 * size.width / 400),
              decoration: BoxDecoration(
                color: Colors.yellow[600],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[900]!, width: 3),
              ),
              child: Column(
                children: [
                  Text(
                    'Catch ${_levels[_currentLevel]['letter']}',
                    style: TextStyle(
                      fontSize: 18 * size.width / 400,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[900],
                    ),
                  ),
                  SizedBox(height: 8 * size.height / 800),
                  Row(
                    children: List.generate(5, (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 2 * size.width / 400),
                      width: 20 * size.width / 400,
                      height: 20 * size.width / 400,
                      decoration: BoxDecoration(
                        color: index < _correctCatches ? Colors.green : Colors.grey[300],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red[900]!, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12 * size.width / 400,
                            fontWeight: FontWeight.bold,
                            color: index < _correctCatches ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    )),
                  ),
                ],
              ),
            ),
          ),
          
          // Level message
          if (_showMessage)
            Center(
              child: Container(
                padding: EdgeInsets.all(24 * size.width / 400),
                margin: EdgeInsets.symmetric(horizontal: 40 * size.width / 400),
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.yellow[600]!, width: 3),
                ),
                child: Text(
                  _currentLevel == 0
                      ? (_isAndroid
                          ? 'Tilt your phone left and right to move the basket.\n\nCatch all the A-notes.\nAvoid the other notes!'
                          : 'Catch all the A-notes.\nAvoid the other notes!')
                      : 'Now catch the ${_levels[_currentLevel]['letter']}s!',
                  style: TextStyle(
                    fontSize: 20 * size.width / 400,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          
          // Arrow buttons - ONLY SHOW ON NON-ANDROID (hidden on Android)
          if (!_isAndroid) ...[
            Positioned(
              bottom: 20 * size.height / 800,
              left: 20 * size.width / 400,
              child: FloatingActionButton(
                heroTag: 'left',
                onPressed: () {
                  setState(() {
                    _basketX = (_basketX - 0.05).clamp(0.0, 1.0);
                  });
                },
                backgroundColor: Colors.red[700],
                child: Icon(Icons.arrow_back, size: 30 * size.width / 400, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 20 * size.height / 800,
              right: 20 * size.width / 400,
              child: FloatingActionButton(
                heroTag: 'right',
                onPressed: () {
                  setState(() {
                    _basketX = (_basketX + 0.05).clamp(0.0, 1.0);
                  });
                },
                backgroundColor: Colors.red[700],
                child: Icon(Icons.arrow_forward, size: 30 * size.width / 400, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}

class FallingNote {
  String note;
  double x;
  double y;
  
  FallingNote({
    required this.note,
    required this.x,
    required this.y,
  });
}