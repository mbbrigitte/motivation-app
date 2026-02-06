import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:async';
import '../services/storage_service.dart';
import 'challenges/instrument_challenge.dart';
import 'challenges/posture_challenge.dart';
import 'challenges/bach_challenge.dart';
import 'challenges/animal_challenge.dart';
import 'challenges/listening_challenge.dart';
import 'challenges/question_challenge.dart';
import 'challenges/notes_challenge.dart';
import 'challenges/guard_challenge.dart';
import 'challenges/memory_challenge.dart';
import 'challenges/opengates_challenge.dart';
import 'practice_finished.dart';

class KnightAdvancer extends StatefulWidget {
  const KnightAdvancer({super.key});

  @override
  State<KnightAdvancer> createState() => _KnightAdvancerState();
}

class _KnightAdvancerState extends State<KnightAdvancer>
    with SingleTickerProviderStateMixin {
  int points = 0;
  int lastHandledMilestone = 0;
  bool isLoading = true;
  Map<String, dynamic> pathsData = {};
  bool showSpeechBubble = false;
  String selectedCharacter = 'knight';

  // Animation
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;

  double animatedXPercent = 0.5;
  double animatedYPercent = 0.9;
  double animatedSizePercent = 0.9;

  // Track the last point we animated to (within the current 25-point journey)
  int lastAnimatedPointInJourney = 0;

  // Speech bubbles - same for all backgrounds
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

  // Background order
  final List<String> backgroundOrder = [
    'instrument_cart',
    'violinist',
    'bach',
    'animal',
    'bird',
    'questionmark',
    'music',
    'guard',
    'castle',
    'castle_gates',
  ];

  // Milestone to challenge mapping
  final Map<int, String> milestoneToChallenge = {
    25: 'instrument_challenge',
    50: 'posture_challenge',
    75: 'bach_challenge',
    100: 'animal_challenge',
    125: 'listening_challenge',
    150: 'question_challenge',
    175: 'notes_challenge',
    200: 'guard_challenge',
    225: 'memory_challenge',
    250: 'opengates_challenge',
  };

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _positionAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );

    _loadPathsAndSetupJourney();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPathsAndSetupJourney() async {
    // Load the JSON file
    try {
      final String jsonString = await rootBundle.loadString('data/knight_paths.json');
      pathsData = json.decode(jsonString);
    } catch (e) {
      print('Error loading knight paths: $e');
      pathsData = {'backgrounds': {}};
    }

    // Load current progress
    points = await StorageService.loadPoints();
    lastHandledMilestone = await StorageService.loadLastHandledMilestone();
    selectedCharacter = await StorageService.loadSelectedCharacter();
    
    int currentMilestone = (points ~/ 25) * 25;
    
    // Check if we just crossed a milestone
    bool justCrossedMilestone = points >= 25 && 
                                currentMilestone > lastHandledMilestone;

    // IMPORTANT: Unlock all challenges up to current milestone
    await _unlockAllPreviousChallenges(currentMilestone);

    // Determine display points (position within current journey)
    int displayPoints;
    if (justCrossedMilestone) {
      displayPoints = 25;
    } else {
      displayPoints = points % 25;
      if (displayPoints == 0 && points > 0) {
        displayPoints = 0;
      }
    }

    // Try to load the last point we saved
    int? savedLastPoint = await StorageService.loadLastAnimatedPoint();
    
    if (savedLastPoint != null && savedLastPoint <= displayPoints) {
      lastAnimatedPointInJourney = savedLastPoint;
      Map<String, double>? savedPos = _getPositionForPoints(savedLastPoint);
      if (savedPos != null) {
        animatedXPercent = savedPos['x']!;
        animatedYPercent = savedPos['y']!;
        animatedSizePercent = savedPos['size']!;
      }
    } else {
      lastAnimatedPointInJourney = 0;
      Map<String, double>? startPos = _getPositionForPoints(0);
      if (startPos != null) {
        animatedXPercent = startPos['x']!;
        animatedYPercent = startPos['y']!;
        animatedSizePercent = startPos['size']!;
      }
    }

    setState(() {
      isLoading = false;
    });

    await Future.delayed(const Duration(milliseconds: 30));

    // Animate point by point to current position
    await _animatePointByPoint(displayPoints);

    // Show speech bubble after animation completes
    if (mounted) {
      setState(() {
        showSpeechBubble = true;
      });
    }

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Handle milestone crossing
    if (justCrossedMilestone) {
      // Save that we've handled this milestone
      await StorageService.saveLastHandledMilestone(currentMilestone);
      
      // Clear knight position so next journey starts fresh
      await StorageService.clearKnightPosition();
      await StorageService.clearLastAnimatedPoint();
      
      // Navigate to the appropriate challenge
      _navigateToChallenge(currentMilestone);
      return;
    }

    // Normal flow - go to practice finished
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PracticeFinished()),
    );
  }

  /// Unlock all challenges from milestone 25 up to currentMilestone
  Future<void> _unlockAllPreviousChallenges(int currentMilestone) async {
    // For each milestone from 25 to currentMilestone (in steps of 25)
    for (int milestone = 25; milestone <= currentMilestone; milestone += 25) {
      if (milestoneToChallenge.containsKey(milestone)) {
        String challengeId = milestoneToChallenge[milestone]!;
        await StorageService.unlockChallenge(challengeId);
      }
    }
  }

  // Animate point by point from lastAnimatedPointInJourney to targetPoint
  Future<void> _animatePointByPoint(int targetPoint) async {
    for (int i = lastAnimatedPointInJourney + 1; i <= targetPoint; i++) {
      if (!mounted) return;
      
      await _animateToPosition(i);
      
      await StorageService.saveLastAnimatedPoint(i);
      lastAnimatedPointInJourney = i;
      
      if (i < targetPoint) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  void _navigateToChallenge(int milestone) {
    int journeyIndex = (milestone ~/ 25) - 1;
    
    if (journeyIndex < 0 || journeyIndex >= backgroundOrder.length) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PracticeFinished()),
      );
      return;
    }

    Widget challengeScreen;
    switch (journeyIndex) {
      case 0:
        challengeScreen = const InstrumentChallenge();
        break;
      case 1:
        challengeScreen = const PostureChallenge();
        break;
      case 2:
        challengeScreen = const BachChallenge(isReplay: false);
        break;
      case 3:
        challengeScreen = const AnimalChallenge();
        break;
      case 4:
        challengeScreen = const ListeningChallenge();
        break;
      case 5:
        challengeScreen = const QuestionChallenge();
        break;
      case 6:
        challengeScreen = BirdNoteGame();
        break;
      case 7:
        challengeScreen = const GuardChallenge();
        break;
      case 8:
        challengeScreen = const MemoryChallenge();
        break;
      case 9:
        challengeScreen = const OpenGatesChallenge();
        break;
      default:
        challengeScreen = const PracticeFinished();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => challengeScreen),
    );
  }

  String _getCurrentBackgroundKey() {
    int journeyIndex = lastHandledMilestone ~/ 25;
    if (journeyIndex >= backgroundOrder.length) {
      journeyIndex = journeyIndex % backgroundOrder.length;
    }
    return backgroundOrder[journeyIndex];
  }

  String _getBackgroundImage() {
    String bgKey = _getCurrentBackgroundKey();
    if (pathsData['backgrounds'] != null && 
        pathsData['backgrounds'][bgKey] != null &&
        pathsData['backgrounds'][bgKey]['image'] != null) {
      return pathsData['backgrounds'][bgKey]['image'];
    }
    return 'assets/images/Background1_instrument_cart.webp';
  }

  String _getJourneyTitle() {
    String bgKey = _getCurrentBackgroundKey();
    if (pathsData['backgrounds'] != null && 
        pathsData['backgrounds'][bgKey] != null &&
        pathsData['backgrounds'][bgKey]['title'] != null) {
      return pathsData['backgrounds'][bgKey]['title'];
    }
    return 'Epic Journey';
  }

  List<dynamic> _getCurrentWaypoints() {
    String bgKey = _getCurrentBackgroundKey();
    if (pathsData['backgrounds'] != null && 
        pathsData['backgrounds'][bgKey] != null &&
        pathsData['backgrounds'][bgKey]['waypoints'] != null) {
      return pathsData['backgrounds'][bgKey]['waypoints'];
    }
    return [];
  }

  Map<String, double>? _getPositionForPoints(int pts) {
    List<dynamic> waypoints = _getCurrentWaypoints();
    
    if (waypoints.isEmpty) {
      return {'x': 0.5, 'y': 0.9, 'size': 0.12};
    }

    int index = pts.clamp(0, 25);
    if (index > waypoints.length - 1) {
      index = waypoints.length - 1;
    }

    var waypoint = waypoints[index];
    return {
      'x': (waypoint['x'] as num).toDouble(),
      'y': (waypoint['y'] as num).toDouble(),
      'size': ((waypoint['size'] as num).toDouble()) * 3.75,
    };
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

  Future<void> _animateToPosition(int displayPoint) async {
    Map<String, double>? targetPos = _getPositionForPoints(displayPoint);
    
    if (targetPos == null) return;

    double startX = animatedXPercent;
    double startY = animatedYPercent;
    double startSize = animatedSizePercent;

    _animationController.reset();

    final completer = Completer<void>();

    void listener() {
      setState(() {
        animatedXPercent =
            startX + (targetPos['x']! - startX) * _positionAnimation.value;
        animatedYPercent =
            startY + (targetPos['y']! - startY) * _positionAnimation.value;
        animatedSizePercent =
            startSize + (targetPos['size']! - startSize) * _positionAnimation.value;
      });
    }

    void statusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        completer.complete();
      }
    }

    _animationController.addListener(listener);
    _animationController.addStatusListener(statusListener);

    _animationController.forward();

    await completer.future;

    _animationController.removeListener(listener);
    _animationController.removeStatusListener(statusListener);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    final knightX = animatedXPercent * screenWidth;
    final knightY = animatedYPercent * screenHeight;
    final knightSize = animatedSizePercent * screenWidth;

    int displayPoints = points - lastHandledMilestone;
    if (displayPoints < 0) displayPoints = 0;
    if (displayPoints > 25) displayPoints = 25;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _getBackgroundImage(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Text(
                      'Background image not found',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            left: knightX - (knightSize / 2),
            top: knightY - knightSize,
            child: Image.asset(
              selectedCharacter.toLowerCase() == 'gerbil'
                  ? 'assets/images/Gerbil_advancer.png'
                  : 'assets/images/Knight.png',
              width: knightSize,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: knightSize,
                  height: knightSize,
                  color: Colors.red,
                  child: Icon(Icons.person, color: Colors.white, size: knightSize * 0.6),
                );
              },
            ),
          ),

          if (showSpeechBubble && _getSpeechBubbleForPoints(displayPoints) != null)
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
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}