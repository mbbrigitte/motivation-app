import 'package:flutter/material.dart';
import 'dart:math';
import '../services/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';


class ParentInfo extends StatefulWidget {
  const ParentInfo({super.key});

  @override
  State<ParentInfo> createState() => _ParentInfoState();
}

class _ParentInfoState extends State<ParentInfo> {
  int totalTokens = 0;
  int currentTokens = 0;
  int totalPoints = 0;
  List<String> unlockedChallenges = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final tokens = await StorageService.loadTokens();
    final total = await StorageService.loadTotalTokens();
    final points = await StorageService.loadPoints();
    final challenges = await StorageService.getUnlockedChallenges();

    if (!mounted) return;
    setState(() {
      currentTokens = tokens;
      totalTokens = total;
      totalPoints = points;
      unlockedChallenges = challenges;
      isLoading = false;
    });
  }

  Future<void> _showRemoveTokensDialog() async {
    final tokensController = TextEditingController();
    final pointsController = TextEditingController();

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Tokens & Points'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How many would you like to remove?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tokensController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tokens to remove',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Points to remove',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final tokens = int.tryParse(tokensController.text) ?? 0;
              final points = int.tryParse(pointsController.text) ?? 0;
              
              if (tokens > 0 || points > 0) {
                Navigator.pop(context, {'tokens': tokens, 'points': points});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Next'),
          ),
        ],
      ),
    );

    if (result != null) {
      _confirmRemoval(result['tokens']!, result['points']!);
    }
  }

  Future<void> _confirmRemoval(int tokensToRemove, int pointsToRemove) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Removal'),
        content: Text(
          'Are you sure you want to remove:\n\n'
          '🪙 $tokensToRemove tokens\n'
          '⭐ $pointsToRemove points\n\n'
          'This will also reset the knight\'s position.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _showMathChallenge(tokensToRemove, pointsToRemove);
    }
  }

  Future<void> _showMathChallenge(int tokensToRemove, int pointsToRemove) async {
    final random = Random();
    
    // Generate a math problem that's hard for kids
    final num1 = 12 + random.nextInt(38); // 12-49
    final num2 = 12 + random.nextInt(38); // 12-49
    final correctAnswer = num1 + num2;
    
    final answerController = TextEditingController();

    final mathResult = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Parent Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Solve this math problem to continue:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              '$num1 + $num2 = ?',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: answerController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Your answer',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final userAnswer = int.tryParse(answerController.text);
              Navigator.pop(context, userAnswer == correctAnswer);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (mathResult == true) {
      await _performRemoval(tokensToRemove, pointsToRemove);
    } else if (mathResult == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect answer. No changes were made.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performRemoval(int tokensToRemove, int pointsToRemove) async {
    // Remove tokens
    int newCurrentTokens = (currentTokens - tokensToRemove).clamp(0, currentTokens);
    int newTotalTokens = (totalTokens - tokensToRemove).clamp(0, totalTokens);
    await StorageService.saveTokens(newCurrentTokens);
    await StorageService.saveTotalTokens(newTotalTokens);

    // Remove points
    int newPoints = (totalPoints - pointsToRemove).clamp(0, totalPoints);
    await StorageService.savePoints(newPoints);
    
    // Calculate which milestone the new point total corresponds to
    int newMilestone = (newPoints / 25).floor();
    
    // Reset last handled milestone
    await StorageService.saveLastHandledMilestone(newMilestone);

    // Reset all challenges, then re-unlock only those up to the new milestone
    await StorageService.resetChallenges();
    
    // Unlock challenges based on milestones reached
    // Milestone mapping (from knight_advancer logic):
    final milestoneToChallenge = {
      1: 'instrument_challenge',
      2: 'posture_challenge',
      3: 'bach_challenge',
      4: 'animal_challenge',
      5: 'listening_challenge',
      6: 'question_challenge',
      7: 'notes_challenge',
      8: 'guard_challenge',
      9: 'memory_challenge',
      10: 'opengates_challenge',
    };
    
    // Re-unlock challenges up to the new milestone
    for (int i = 1; i <= newMilestone && i <= 10; i++) {
      if (milestoneToChallenge.containsKey(i)) {
        await StorageService.unlockChallenge(milestoneToChallenge[i]!);
      }
    }

    // Reset knight position (this clears x, y, size, and lastAnimatedPoint)
    await StorageService.clearKnightPosition();

    // Reload stats
    await _loadStats();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Removed $tokensToRemove tokens and $pointsToRemove points.\n'
            'Knight at milestone $newMilestone. Challenges reset appropriately.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: const Text('For Parents'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionCard(
                    title: "👨‍👩‍👧 Introduction",
                    children: [
                      _p(
                        "Motivating a very young child to practice the violin can be incredibly hard. "
                        "This app makes it easier by turning practice into a fun game – without needing "
                        "to give a reward every single time.",
                      ),
                      _p(
                        "The approach is aligned with modern teaching methods: children make the biggest progress "
                        "when they *listen* regularly. Ear training, major/minor listening, and becoming familiar "
                        "with their repertoire builds intrinsic motivation. It helps them appreciate music, develop "
                        "a musical identity, and ultimately play better.",
                      ),
                      _p(
                        "As children progress, they unlock small musical challenges – learning violin parts, basic "
                        "theory, note-reading, and more, always wrapped in fun discovery.",
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _rewardsCard(),

                  const SizedBox(height: 20),

                  _sectionCard(
                    title: "🪙 How the System Works",
                    children: [
                      _bullet("Your child earns tokens by completing practice sessions and challenges."),
                      _bullet("Each completed quest awards 1 token."),
                      _bullet(
                        "Tokens can be spent on rewards that *you* decide. Selecting the right rewards helps your child feel ownership and excitement.",
                      ),
                      _bullet(
                        "Points are different: they accumulate forever through practice and ear training and unlock milestones.",
                      ),
                      _bullet("Replay challenges as much as you like – replays are for learning and fun."),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _sectionCard(
                    title: "🎮 Challenges",
                    children: [
                      _bullet("Challenges unlock automatically after practice sessions."),
                      _bullet("They teach violin parts, note reading, listening skills, theory basics (major/minor), and more."),
                      _bullet("The 'Ear Training & More' button appears after practicing."),
                      _bullet("First completion awards tokens; replays do not."),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _progressCard(),

                  const SizedBox(height: 20),

                  _adjustmentSection(),

                  const SizedBox(height: 20),

                  _sectionCard(
                    title: "💡 Tips for Parents",
                    children: [
                      _bullet("Encourage short but consistent daily practice."),
                      _bullet("Celebrate both tokens and long-term points."),
                      _bullet("Consider letting your child help choose the reward list."),
                      _bullet("Replaying challenges reinforces learning – encourage it."),
                      _bullet("Listening to their repertoire (even passively) builds musicality."),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _contactSection(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ------------------------------
  // UI HELPERS
  // ------------------------------

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900])),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _rewardsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🎁 Reward Suggestions",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red[900],
            ),
          ),
          const SizedBox(height: 12),

          _reward("10 Tokens", Icons.tv, "Watch a 15-minute show (e.g., Bluey)"),
          _reward("25 Tokens", Icons.local_movies, "Movie night with popcorn"),
          _reward("50 Tokens", Icons.toys, "\$5 toward a toy"),
          _reward("250 Tokens", Icons.smart_toy,
              "A special toy or robot (50–100\$ range) – something the child truly wants"),

          const SizedBox(height: 12),
          _p(
            "These are only examples. Think about which rewards match your family values and "
            "your child's personality. A good reward list makes the whole system work smoothly.",
          ),
        ],
      ),
    );
  }

  Widget _reward(String title, IconData icon, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.orange[800]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _progressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "📊 Progress Overview",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red[900],
            ),
          ),
          const SizedBox(height: 16),
          _stat("🪙 Current Tokens", "$currentTokens"),
          _stat("🏆 Total Tokens Earned", "$totalTokens"),
          _stat("⭐ Total Points", "$totalPoints"),
          _stat("🔓 Challenges Unlocked", "${unlockedChallenges.length}"),
        ],
      ),
    );
  }

  Widget _adjustmentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "⚙️ Adjust Tokens & Points",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange[900],
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            "Made a mistake? You can remove tokens or points here.",
            style: TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showRemoveTokensDialog,
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text('Remove Tokens & Points'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _contactSection() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.purple[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.purple[200]!, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "📧 Contact & Resources",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.purple[900],
          ),
        ),
        const SizedBox(height: 12),
        
        // Email
        InkWell(
          onTap: () async {
            final Uri emailUri = Uri(
              scheme: 'mailto',
              path: 'violinadventure@proton.me',
            );
            if (await canLaunchUrl(emailUri)) {
              await launchUrl(emailUri);
            }
          },
          child: Row(
            children: [
              Icon(Icons.email, size: 20, color: Colors.purple[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "violinadventure@proton.me",
                  style: TextStyle(
                    fontSize: 14, 
                    color: Colors.purple[800],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Website
        InkWell(
          onTap: () async {
            final Uri url = Uri.parse('https://violinadventure.carrd.co/');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
          child: Row(
            children: [
              Icon(Icons.language, size: 20, color: Colors.purple[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "https://violinadventure.carrd.co/",
                  style: TextStyle(
                    fontSize: 14, 
                    color: Colors.purple[800],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Notebook info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.book, size: 20, color: Colors.purple[900]),
                  const SizedBox(width: 8),
                  Text(
                    "Practice Notebooks Available",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Enhance your child's practice with our specially designed "
                "practice notebooks! Visit our website to learn more and purchase.",
                style: TextStyle(fontSize: 13, color: Colors.purple[800]),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          "Questions or feedback? We'd love to hear from you!",
          style: TextStyle(
            fontSize: 13, 
            color: Colors.purple[700],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );
}

  // ------------------------------
  // SMALL UI UTILITIES
  // ------------------------------

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _p(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _stat(String name, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 16)),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}