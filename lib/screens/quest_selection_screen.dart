import 'package:flutter/material.dart';
import 'tuning_question_screen.dart'; // Changed import
import '../widgets/sword_icon.dart';

class QuestSelectionScreen extends StatefulWidget {
  const QuestSelectionScreen({super.key});

  @override
  State<QuestSelectionScreen> createState() => _QuestSelectionScreenState();
}

class _QuestSelectionScreenState extends State<QuestSelectionScreen> {
  // List of quests with token info
  final List<Map<String, String>> quests = [
    {'name': '15 minute practice', 'tokens': '+3 tokens'},
    {'name': '30 minutes practice', 'tokens': '+6 tokens'},
    {'name': 'Self-motivated hero', 'tokens': '+1 token'},
    {'name': 'Practice scale with goal setting', 'tokens': '+1 token'},
    {'name': 'Listen to Suzuki songs', 'tokens': '+1 token'},
  ];

  // Track selected quests
  final Set<int> _selectedQuests = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title with swords
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SwordIcon(size: 40),
                    const SizedBox(width: 16),
                    const Text(
                      'Quests to Choose From',
                      style: TextStyle(
                        color: Color(0xFFB22222),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const SwordIcon(size: 40),
                  ],
                ),
              ),

              // Quest buttons
              for (int i = 0; i < quests.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedQuests.contains(i)
                          ? Colors.green
                          : Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          quests[i]['name']!,
                          style: const TextStyle(fontSize: 20),
                        ),
                        Text(
                          quests[i]['tokens']!,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // Start practice button - now goes to tuning question
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB22222),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () {
                  // Navigate to the tuning question screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TuningQuestionScreen()),
                  );
                },
                child: const Text(
                  'Start Practice',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}