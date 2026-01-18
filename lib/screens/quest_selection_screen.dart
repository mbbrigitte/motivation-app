import 'package:flutter/material.dart';
import 'tuning_question_screen.dart';
import 'parent_info.dart';
import 'challenges_list.dart';
import 'treasure_chest_page.dart';
import '../widgets/sword_icon.dart';

class QuestSelectionScreen extends StatefulWidget {
  const QuestSelectionScreen({super.key});

  @override
  State<QuestSelectionScreen> createState() => _QuestSelectionScreenState();
}

class _QuestSelectionScreenState extends State<QuestSelectionScreen> {
  final List<Map<String, dynamic>> quests = [
    {'name': '15 minute practice', 'tokens': '+3 tokens'},
    {'name': '30 minutes practice', 'tokens': '+6 tokens'},
    {
      'name': 'Self-motivated hero',
      'tokens': '+1 token',
      'info': 'If you are asked to practice violin and you say yes the first time, you are a self-motivated hero!'
    },
    {'name': 'Practice scale with goal setting', 'tokens': '+1 token'},
    {'name': 'Listen to pieces from your repertoire', 'tokens': '+1 token'},
    {'name': 'Replay challenges only', 'tokens': '', 'isSpecial': true},
  ];

  final Set<int> _selectedQuests = {};

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _handleStartPractice() {
    // Check if only "Listen to pieces" (index 4) is selected
    if (_selectedQuests.length == 1 && _selectedQuests.contains(4)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TreasureChestPage(),
        ),
      );
      return;
    }

    // Check if only "Replay challenges" (index 5) is selected
    if (_selectedQuests.length == 1 && _selectedQuests.contains(5)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ChallengesList(),
        ),
      );
      return;
    }

    // Default: go to tuning question
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TuningQuestionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding =
        MediaQuery.of(context).size.width * 0.05;

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
                          'Choose your quests',
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
                  final quest = quests[i];
                  final isSpecial = quest['isSpecial'] == true;
                  final hasInfo = quest['info'] != null;
                  final isReplayChallenges = i == 5;

                  // Center and make replay challenges button shorter
                  if (isReplayChallenges) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedQuests.contains(i)
                                  ? Colors.green
                                  : Colors.purple.shade300,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              // Check if any other quest is selected
                              if (_selectedQuests.isNotEmpty && !_selectedQuests.contains(i)) {
                                _showWarningDialog(
                                  'Replay challenges will be available after practice. You only have to select it here if you do not practice at all today.'
                                );
                                return;
                              }
                              
                              setState(() {
                                if (_selectedQuests.contains(i)) {
                                  _selectedQuests.remove(i);
                                } else {
                                  _selectedQuests.add(i);
                                }
                              });
                            },
                            child: Text(
                              quest['name']!,
                              style: const TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                              softWrap: true,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

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
                        // Check if trying to select Self-motivated hero
                        if (i == 2) { // Self-motivated hero
                          // Block if ONLY "Listen to pieces" (4) is selected
                          if (_selectedQuests.length == 1 && _selectedQuests.contains(4)) {
                            _showWarningDialog('Self motivated hero not available without practicing');
                            return;
                          }
                          // Block if ONLY "Replay challenges" (5) is selected
                          if (_selectedQuests.length == 1 && _selectedQuests.contains(5)) {
                            _showWarningDialog('Self motivated hero not available without practicing');
                            return;
                          }
                        }
                        
                        // Check if trying to select Listen to pieces or Replay challenges when ONLY Self-motivated hero is selected
                        if (i == 4 || i == 5) { // Listen to pieces or Replay challenges
                          if (_selectedQuests.length == 1 && _selectedQuests.contains(2)) {
                            _showWarningDialog('Self motivated hero not available without practicing');
                            return;
                          }
                        }

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
                              quest['name']!,
                              style: const TextStyle(fontSize: 18),
                              softWrap: true,
                            ),
                          ),
                          if (hasInfo) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showInfoDialog(quest['info']!),
                              child: const Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                          if (quest['tokens']!.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Text(
                              quest['tokens']!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
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
                  onPressed: _handleStartPractice,
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