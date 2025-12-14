import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'guard_challenge.dart';
import 'instrument_challenge.dart';
import 'wishing_well_challenge.dart';
import 'practice_finished.dart';

class KnightAdvancer extends StatefulWidget {
  const KnightAdvancer({super.key});

  @override
  State<KnightAdvancer> createState() => _KnightAdvancerState();
}

class _KnightAdvancerState extends State<KnightAdvancer>
    with SingleTickerProviderStateMixin {
  int points = 0; // Changed from tokensCollected
  int lastHandledMilestone = 0; // NEW: track the last milestone we handled
  bool isLoading = true;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;

  // Use percentages instead of absolute pixels
  double animatedXPercent = 0.558;
  double animatedYPercent = 0.998;
  double animatedSizePercent = 0.45; // Increased for better visibility

  // Knight positions as percentages of screen dimensions
  // Size values increased for better visibility on small screens
  final Map<String, Map<String, double>> positions = {
    '1-3': {'x': 0.458, 'y': 0.998, 'size': 0.5},
    '4-6': {'x': 0.321, 'y': 0.908, 'size': 0.42},
    '7-9': {'x': 0.409, 'y': 0.739, 'size': 0.35},
    '10-12': {'x': 0.390, 'y': 0.710, 'size': 0.32},
    '13-15': {'x': 0.376, 'y': 0.691, 'size': 0.30},
    '16-18': {'x': 0.350, 'y': 0.645, 'size': 0.27},
    '19-21': {'x': 0.389, 'y': 0.580, 'size': 0.25},
    '22-24': {'x': 0.368, 'y': 0.576, 'size': 0.23},
    '25': {'x': 0.347, 'y': 0.508, 'size': 0.22},
  };

  // Speech bubbles
  final Map<String, String> speechBubbles = {
    '1-3': "Great start into this new challenge!",
    '4-6': "I'm making progress!",
    '7-9': "I can already see the goal. Keep going!",
    '10-12': "Halfway there!",
    '13-15': "I can see something ahead!",
    '16-18': "Almost there now...",
    '19-21': "So close!",
    '22-24': "Just a bit further!",
    '25': "You have reached your destination! Well done! Are you ready for an extra challenge?",
  };

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _positionAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _loadAndSetupJourney();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getDestinationImage() {
    // Show destination based on LAST HANDLED milestone from storage
    // This ensures we show the correct destination even after crossing a milestone
    int journey = lastHandledMilestone ~/ 25;
    
    switch (journey) {
      case 0:
        return 'assets/images/Instrument_wagon.png';
      case 1:
        return 'assets/images/Wishing_well.png';
      case 2:
        return 'assets/images/Treasure_chest_with_dragon.png';
      case 3:
        return 'assets/images/Guard.png';
      case 4:
        return 'assets/images/Beethoven_house.png';
      case 5:
        return 'assets/images/JS_Bach_on_Bench_paint.png';
      case 6:
        return 'assets/images/Younger_house.png';
      case 7:
        return 'assets/images/JS_Bach_on_Bench_paint.png';
      case 8:
        return 'assets/images/Wishing_well.png';
      case 9:
        return 'assets/images/Treasure_chest_with_dragon.png';
      default:
        int cycleIndex = journey % 3;
        if (cycleIndex == 0) return 'assets/images/Instrument_wagon.png';
        if (cycleIndex == 1) return 'assets/images/Guard.png';
        return 'assets/images/Treasure_chest_with_dragon.png';
    }
  }

  String _getBackgroundImage() {
    // Alternates between day and night based on milestone
    int journey = lastHandledMilestone ~/ 25;
    return journey % 2 == 0 ? 'assets/images/day.png' : 'assets/images/night.png';
  }

  String _getJourneyTitle() {
    // Show title based on LAST HANDLED milestone from storage
    int journey = lastHandledMilestone ~/ 25;
    
    switch (journey) {
      case 0:
        return 'Journey to the Instrument Wagon';
      case 1:
        return 'The Wishing Well';
      case 2:
        return 'Dragon\'s Treasure';
      case 3:
        return 'Journey to the Guard';
      case 4:
        return 'Beethoven\'s House';
      case 5:
        return 'Bach\'s Bench';
      case 6:
        return 'Younger House';
      default:
        return 'Epic Journey ${journey + 1}';
    }
  }

  Future<void> _loadAndSetupJourney() async {
    points = await StorageService.loadPoints(); // Load points instead of tokens

    lastHandledMilestone = await StorageService.loadLastHandledMilestone(); // Load this first!
    int currentMilestone = (points ~/ 25) * 25;
    
    // Check if we just crossed a milestone
    bool justCrossedMilestone = points >= 25 && 
                                currentMilestone > lastHandledMilestone;

    // Determine display points
    int displayPoints;
    if (justCrossedMilestone) {
      // Just crossed milestone - stop at position 25
      displayPoints = 25;
    } else {
      // Normal journey - show position within current 25-point journey
      displayPoints = points % 25;
      if (displayPoints == 0 && points > 0) {
        displayPoints = 0;
      }
    }

    // Load knight's last saved position (starting point for animation)
    double? savedX = await StorageService.loadAnimatedX();
    double? savedY = await StorageService.loadAnimatedY();
    double? savedSize = await StorageService.loadAnimatedSize();

    if (savedX != null && savedY != null && savedSize != null) {
      // Check if values are absolute (>10) or percentage (<2)
      if (savedX > 10) {
        // Old absolute values - convert to percentages
        animatedXPercent = savedX / 1200;
        animatedYPercent = savedY / 1200;
        animatedSizePercent = savedSize / 1200;
      } else {
        // Already percentages
        animatedXPercent = savedX;
        animatedYPercent = savedY;
        animatedSizePercent = savedSize;
      }
    } else {
      // No saved position - use default starting position
      Map<String, double> startPos = _getPositionForPoints(displayPoints);
      animatedXPercent = startPos['x']!;
      animatedYPercent = startPos['y']!;
      animatedSizePercent = startPos['size']!;
    }

    setState(() {
      isLoading = false;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    // Animate to target position
    _animateToPosition(displayPoints);

    await Future.delayed(const Duration(seconds: 8));

    if (!mounted) return;

    // Handle milestone crossing
    if (justCrossedMilestone) {
      // Save that we've handled this milestone
      await StorageService.saveLastHandledMilestone(currentMilestone);
      
      // Clear knight position so next journey starts fresh
      await StorageService.clearKnightPosition();
      
      if (currentMilestone == 25) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const InstrumentChallenge()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GuardChallenge()),
        );
      }
      return;
    }

    // Normal flow - go to practice finished
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PracticeFinished()),
    );
  }

  Map<String, double> _getPositionForPoints(int pts) {
    if (pts >= 25) return positions['25']!;
    if (pts >= 22) return positions['22-24']!;
    if (pts >= 19) return positions['19-21']!;
    if (pts >= 16) return positions['16-18']!;
    if (pts >= 13) return positions['13-15']!;
    if (pts >= 10) return positions['10-12']!;
    if (pts >= 7) return positions['7-9']!;
    if (pts >= 4) return positions['4-6']!;
    if (pts >= 1) return positions['1-3']!;
    return positions['1-3']!;
  }

  String? _getSpeechBubbleForPoints(int pts) {
    if (pts >= 25) return speechBubbles['25'];
    if (pts >= 22) return speechBubbles['22-24'];
    if (pts >= 19) return speechBubbles['19-21'];
    if (pts >= 16) return speechBubbles['16-18'];
    if (pts >= 13) return speechBubbles['13-15'];
    if (pts >= 10) return speechBubbles['10-12'];
    if (pts >= 7) return speechBubbles['7-9'];
    if (pts >= 4) return speechBubbles['4-6'];
    if (pts >= 1) return speechBubbles['1-3'];
    return null;
  }

  void _animateToPosition(int displayPoints) {
    Map<String, double> targetPos = _getPositionForPoints(displayPoints);

    double startX = animatedXPercent;
    double startY = animatedYPercent;
    double startSize = animatedSizePercent;

    _animationController.reset();

    _animationController.addListener(() async {
      setState(() {
        animatedXPercent =
            startX + (targetPos['x']! - startX) * _positionAnimation.value;
        animatedYPercent =
            startY + (targetPos['y']! - startY) * _positionAnimation.value;
        animatedSizePercent =
            startSize + (targetPos['size']! - startSize) * _positionAnimation.value;
      });

      // Save position continuously during animation
      await StorageService.saveAnimatedX(animatedXPercent);
      await StorageService.saveAnimatedY(animatedYPercent);
      await StorageService.saveAnimatedSize(animatedSizePercent);
    });

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Get screen dimensions
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Convert percentages to actual pixels based on current screen size
    final knightX = animatedXPercent * screenWidth;
    final knightY = animatedYPercent * screenHeight;
    final knightSize = animatedSizePercent * screenWidth;

    // Destination position (also relative) - increased size
    final destX = 0.184 * screenWidth;
    final destY = 0.27 * screenHeight;
    final destSize = 0.28 * screenWidth; // Increased for visibility

    // Calculate display points for speech bubble
    int displayPoints = points - lastHandledMilestone;
    if (points % 25 == 0 && points > 0) {
      displayPoints = 25;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background image - alternates between day and night
          Positioned.fill(
            child: Image.asset(
              _getBackgroundImage(),
              fit: BoxFit.cover,
            ),
          ),

          // Destination image (Guard, Wishing Well, etc.)
          Positioned(
            left: destX,
            top: destY,
            child: Image.asset(
              _getDestinationImage(),
              width: destSize,
            ),
          ),

          // Knight sprite
          Positioned(
            left: knightX - (knightSize / 2),
            top: knightY - knightSize,
            child: Image.asset(
              'assets/images/Knight.png',
              width: knightSize,
            ),
          ),

          // Speech bubble - made responsive
          if (_animationController.isCompleted &&
              _getSpeechBubbleForPoints(displayPoints) != null)
            Positioned(
              left: knightX + (screenWidth * 0.02),
              top: knightY - knightSize - (screenHeight * 0.08),
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                constraints: BoxConstraints(maxWidth: screenWidth * 0.4),
                child: Text(
                  _getSpeechBubbleForPoints(displayPoints)!,
                  style: TextStyle(fontSize: screenWidth * 0.035),
                ),
              ),
            ), 

          // Centered info overlay - made responsive
          Positioned(
            top: screenHeight * 0.05,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.015,
                ),
                decoration: BoxDecoration(
                  color: Colors.red[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.yellow[600]!, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '${_getJourneyTitle()} - Points: $points',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}