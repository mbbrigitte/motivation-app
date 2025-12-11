import 'package:flutter/material.dart';
import 'tuning_question_screen.dart';
import 'parent_info.dart';
import '../widgets/sword_icon.dart';

class QuestSelectionScreen extends StatefulWidget {
  const QuestSelectionScreen({super.key});

  @override
  State<QuestSelectionScreen> createState() => _QuestSelectionScreenState();
}

class _QuestSelectionScreenState extends State<QuestSelectionScreen> {
  final List<Map<String, String>> quests = [
    {'name': '15 minute practice', 'tokens': '+3 tokens'},
    {'name': '30 minutes practice', 'tokens': '+6 tokens'},
    {'name': 'Self-motivated hero', 'tokens': '+1 token'},
    {'name': 'Practice scale with goal setting', 'tokens': '+1 token'},
    {'name': 'Listen to violin pieces', 'tokens': '+1 token'},
  ];

  final Set<int> _selectedQuests = {};

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding =
        MediaQuery.of(context).size.width * 0.05; // responsive padding

    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // -------------------------
                //        TITLE ROW
                // -------------------------
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Row(
                    children: [
                      const SwordIcon(size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Quests to Choose From',
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: const TextStyle(
                            color: Color(0xFFB22222),
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const SwordIcon(size: 32),
                    ],
                  ),
                ),

                // -------------------------
                //        QUEST BUTTONS
                // -------------------------
                ...List.generate(quests.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedQuests.contains(i)
                            ? Colors.green
                            : Colors.amber,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          if (_selectedQuests.contains(i)) {
                            _selectedQuests.remove(i);
                          } else {
                            _selectedQuests.add(i);
                          }
                        });
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              quests[i]['name']!,
                              style: const TextStyle(fontSize: 18),
                              softWrap: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            quests[i]['tokens']!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 40),

                // -------------------------
                //     START BUTTON
                // -------------------------
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TuningQuestionScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Start Practice',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 30),

                // -------------------------
                //   PARENT INFO BUTTON
                // -------------------------
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB22222),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentInfo(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 28),
                  label: const Text(
                    'Parent Info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}