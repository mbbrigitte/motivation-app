// ========== practice_finished.dart ==========
import 'package:flutter/material.dart';
import 'package:flutter_testapplication/screens/quest_selection_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'challenges_list.dart';
import 'parent_info.dart';
import 'exit_screen.dart';

class PracticeFinished extends StatefulWidget {
  const PracticeFinished({super.key});

  @override
  State<PracticeFinished> createState() => _PracticeFinishedState();
}

class _PracticeFinishedState extends State<PracticeFinished> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  void _playThankYouAudio() async {
    try {
      await _audioPlayer.play(AssetSource('audio/WeNeedParty.m4a'));
      
      // When audio finishes, go to exit screen
      _audioPlayer.onPlayerComplete.listen((event) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ExitScreen(),
          ),
        );
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[800],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Parent info button in top-right corner
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                Icons.info_outline,
                size: 32,
                color: Colors.red[900],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ParentInfo(),
                  ),
                );
              },
              tooltip: 'For Parents',
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Fancy title
              Text(
                'Well done,\nbrave knight!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                  shadows: [
                    Shadow(
                      offset: const Offset(3, 3),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                  fontFamily: 'Georgia',
                  decoration: TextDecoration.none,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Prompt text above buttons
              Text(
                'Next, I want to...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                  shadows: [
                    Shadow(
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Three buttons in a row - responsive to screen size
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate button size based on screen width
                  final screenWidth = MediaQuery.of(context).size.width;
                  final buttonSize = (screenWidth * 0.20).clamp(60.0, 100.0);
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Practice more" button
                      Expanded(
                        child: _buildCustomButton(
                          context: context,
                          imagePath: 'assets/images/Play_more_button.webp',
                          label: '...practice more',
                          buttonSize: buttonSize,
                          tooltip: 'Back to quest selection',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QuestSelectionScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Ear training & challenges button
                      Expanded(
                        child: _buildCustomButton(
                          context: context,
                          imagePath: 'assets/images/Eartraining_and_Game_button.webp',
                          label: '...do more challenges\nand ear training',
                          buttonSize: buttonSize,
                          tooltip: 'To the challenges',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChallengesList(),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // "See you later" button - plays audio only
                      Expanded(
                        child: _buildCustomButton(
                          context: context,
                          imagePath: 'assets/images/Thanks_bye_button.webp',
                          label: '...nothing, I am done,\nthank you!',
                          buttonSize: buttonSize,
                          tooltip: 'Goodbye',
                          onPressed: _playThankYouAudio,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomButton({
    required BuildContext context,
    required String imagePath,
    required String label,
    required double buttonSize,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom image button
            Container(
              width: buttonSize,
              height: buttonSize,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Label text below the button
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (buttonSize * 0.15).clamp(12.0, 16.0),
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}