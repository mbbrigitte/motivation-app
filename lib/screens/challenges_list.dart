import 'package:flutter/material.dart';
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

class ChallengeItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  ChallengeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class ChallengesList extends StatefulWidget {
  const ChallengesList({super.key});

  @override
  State<ChallengesList> createState() => _ChallengesListState();
}

class _ChallengesListState extends State<ChallengesList> {
  List<String> unlockedChallenges = [];
  bool isLoading = true;

  final List<ChallengeItem> allChallenges = [
    ChallengeItem(
      id: 'instrument_challenge',
      title: 'Journey to the Instrument Wagon',
      description: 'Build the violin and learn its parts',
      icon: Icons.music_note,
    ),
    ChallengeItem(
      id: 'posture_challenge',
      title: 'Journey to the Violinist',
      description: 'Match posture pairs correctly',
      icon: Icons.accessibility_new,
    ),
    ChallengeItem(
      id: 'bach_challenge',
      title: 'Visit Johann Sebastian Bach',
      description: 'Complete the Bach challenge',
      icon: Icons.piano,
    ),
    ChallengeItem(
      id: 'animal_challenge',
      title: 'Journey to the Enchanted Animal',
      description: 'Match the magical animals',
      icon: Icons.pets,
    ),
    ChallengeItem(
      id: 'listening_challenge',
      title: 'Journey to the Magical Bird',
      description: 'Match musical terms and dynamics',
      icon: Icons.hearing,
    ),
    ChallengeItem(
      id: 'question_challenge',
      title: 'Get the Box with the Question Mark',
      description: 'Solve the mysteries',
      icon: Icons.help_outline,
    ),
    ChallengeItem(
      id: 'notes_challenge',
      title: 'Journey Along Music',
      description: 'Match musical notes',
      icon: Icons.library_music,
    ),
    ChallengeItem(
      id: 'guard_challenge',
      title: 'Journey to the Guard',
      description: 'Play quietly to not wake the guard!',
      icon: Icons.volume_down,
    ),
    ChallengeItem(
      id: 'memory_challenge',
      title: 'Climb to the Castle',
      description: 'Test your musical memory',
      icon: Icons.lightbulb_outline,
    ),
    ChallengeItem(
      id: 'opengates_challenge',
      title: 'The Castle',
      description: 'Open the castle gates',
      icon: Icons.castle,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUnlockedChallenges();
  }

  Future<void> _loadUnlockedChallenges() async {
    final unlocked = await StorageService.getUnlockedChallenges();
    setState(() {
      unlockedChallenges = unlocked;
      isLoading = false;
    });
  }

  bool _isChallengeUnlocked(String challengeId) {
    return unlockedChallenges.contains(challengeId);
  }

  void _onChallengePressed(ChallengeItem challenge) {
    if (!_isChallengeUnlocked(challenge.id)) {
      // Show locked message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.orange[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white, width: 3),
          ),
          content: const Text(
            'This challenge is locked!\nComplete more practice sessions to unlock it.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Navigate to the challenge
    switch (challenge.id) {
      case 'instrument_challenge':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const InstrumentChallenge(isReplay: true),
          ),
        );
        break;
      case 'posture_challenge':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PostureChallenge(isReplay: true),
          ),
        );
        break;
      case 'bach_challenge':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BachChallenge(isReplay: true),
          ),
        );
        break;
      case 'animal_challenge':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AnimalChallenge(isReplay: true),
          ),
        );
        break;
      case 'listening_challenge':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ListeningChallenge(isReplay: true),
          ),
        );
        break;
      case 'question_challenge':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const QuestionChallenge(isReplay: true),
          ),
        );
        break;
      case 'notes_challenge':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotesChallenge(isReplay: true),
          ),
        );
        break;
      case 'guard_challenge':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GuardChallenge(isReplay: true),
          ),
        );
        break;
      case 'memory_challenge':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MemoryChallenge(isReplay: true),
          ),
        );
        break;
      case 'opengates_challenge':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OpenGatesChallenge(isReplay: true),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This challenge is coming soon!')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFDAA520),
        appBar: AppBar(
          title: const Text('Challenges'),
          backgroundColor: Colors.red[900],
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: const Text('Ear Training & More Challenges'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_open, color: Colors.green[700], size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Unlocked: ${unlockedChallenges.length}/${allChallenges.length}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[900],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: allChallenges.length,
                itemBuilder: (context, index) {
                  final challenge = allChallenges[index];
                  final isUnlocked = _isChallengeUnlocked(challenge.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Opacity(
                      opacity: isUnlocked ? 1.0 : 0.5,
                      child: InkWell(
                        onTap: () => _onChallengePressed(challenge),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isUnlocked ? Colors.green : Colors.grey,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: isUnlocked
                                      ? Colors.green[100]
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  challenge.icon,
                                  size: 32,
                                  color: isUnlocked
                                      ? Colors.green[700]
                                      : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            challenge.title,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red[900],
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          isUnlocked ? Icons.lock_open : Icons.lock,
                                          color: isUnlocked
                                              ? Colors.green[700]
                                              : Colors.grey[600],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      challenge.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: isUnlocked ? Colors.red[900] : Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}