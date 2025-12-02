import 'package:flutter/material.dart';
import '../services/storage_service.dart';

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
                        "This app makes it easier by turning practice into a fun game — without needing "
                        "to give a reward every single time.",
                      ),
                      _p(
                        "The approach is aligned with modern teaching methods: children make the biggest progress "
                        "when they *listen* regularly. Ear training, major/minor listening, and becoming familiar "
                        "with their repertoire builds intrinsic motivation. It helps them appreciate music, develop "
                        "a musical identity, and ultimately play better.",
                      ),
                      _p(
                        "As children progress, they unlock small musical challenges — learning violin parts, basic "
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
                      _bullet("Replay challenges as much as you like — replays are for learning and fun."),
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

                  _sectionCard(
                    title: "💡 Tips for Parents",
                    children: [
                      _bullet("Encourage short but consistent daily practice."),
                      _bullet("Celebrate both tokens and long-term points."),
                      _bullet("Consider letting your child help choose the reward list."),
                      _bullet("Replaying challenges reinforces learning — encourage it."),
                      _bullet("Listening to their repertoire (even passively) builds musicality."),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _resetSection(),

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
              "A special toy or robot (50–100\$ range) — something the child truly wants"),

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

  Widget _resetSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🔧 Developer Testing",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[900],
            ),
          ),
          const SizedBox(height: 12),

          const Text(
              "These buttons reset parts of the app for testing purposes.",
              style: TextStyle(fontSize: 14)),

          const SizedBox(height: 16),

          _resetButton("Reset Tokens", Icons.refresh, Colors.orange[700], () async {
            if (await _confirm("Reset Tokens",
                "This resets current and total tokens to 0.")) {
              await StorageService.saveTokens(0);
              await StorageService.saveTotalTokens(0);
              _loadStats();
            }
          }),

          const SizedBox(height: 8),

          _resetButton("Reset Points", Icons.star_border, Colors.orange[700], () async {
            if (await _confirm("Reset Points", "This resets all points to 0.")) {
              await StorageService.resetPoints();
              _loadStats();
            }
          }),

          const SizedBox(height: 8),

          _resetButton(
              "Reset Challenges", Icons.lock_reset, Colors.orange[700],
              () async {
            if (await _confirm("Reset Challenges",
                "This locks all challenges again.")) {
              await StorageService.resetChallenges();
              _loadStats();
            }
          }),

          const Divider(height: 30),

          _resetButton("Reset ALL Progress", Icons.delete_forever,
              Colors.red[700], () async {
            if (await _confirm("Reset ALL",
                "This resets tokens, points, and challenges. Cannot be undone.")) {
              await StorageService.resetTokens();
              await StorageService.resetPoints();
              await StorageService.resetChallenges();
              _loadStats();
            }
          }),
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
            "📧 Questions or Feedback?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'd love to hear from you!\n"
            "brigitte.mueller@yahoo.ca",
            style: TextStyle(fontSize: 14, color: Colors.purple[800]),
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

  Widget _resetButton(
      String label, IconData icon, Color? color, Future<void> Function() onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<bool> _confirm(String title, String msg) async {
    final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(msg),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text("Reset"),
              )
            ],
          ),
        ) ??
        false;
    return result;
  }
}
