import 'package:flutter/material.dart';
import 'dart:async';
import '../services/storage_service.dart';
import 'practice_finished.dart';

class MemoryChallenge extends StatefulWidget {
  final bool isReplay;
  
  const MemoryChallenge({super.key, this.isReplay = false});

  @override
  State<MemoryChallenge> createState() => _MemoryChallengeState();
}

class _MemoryChallengeState extends State<MemoryChallenge> with TickerProviderStateMixin {
  int _currentTokens = 0;
  List<MemoryCard> _cards = [];
  List<int> _flippedIndices = [];
  bool _isChecking = false;
  Set<int> _matchedIndices = {};
  int _matchesFound = 0;
  final int _totalPairs = 5;
  
  late Stopwatch _stopwatch;
  late Timer _timer;
  String _elapsedTime = '0:00';

  @override
  void initState() {
    super.initState();
    _loadTokens();
    _initializeCards();
    
    // Initialize and start stopwatch
    _stopwatch = Stopwatch();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = _formatTime(_stopwatch.elapsed);
        });
      }
    });
    
    // Unlock this challenge when first accessed (not in replay mode)
    if (!widget.isReplay) {
      StorageService.unlockChallenge('memory_challenge');
    }
  }
  
  String _formatTime(Duration duration) {
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _loadTokens() async {
    int tokens = await StorageService.loadTokens();
    setState(() {
      _currentTokens = tokens;
    });
  }

  void _initializeCards() {
    List<MemoryCard> cards = [
      MemoryCard(id: 0, content: 'Allegro', type: CardType.text, pairId: 0),
      MemoryCard(id: 1, content: 'Happy', type: CardType.text, pairId: 0),
      MemoryCard(id: 2, content: 'Staccato', type: CardType.text, pairId: 1),
      MemoryCard(id: 3, content: 'Detached', type: CardType.text, pairId: 1),
      MemoryCard(id: 4, content: '🎻', type: CardType.emoji, pairId: 2),
      MemoryCard(id: 5, content: 'Violin', type: CardType.text, pairId: 2),
      MemoryCard(id: 6, content: '♩', type: CardType.emoji, pairId: 3),
      MemoryCard(id: 7, content: 'Quarter note', type: CardType.text, pairId: 3),
      MemoryCard(id: 8, content: 'Pepperoni pizza rhythm', type: CardType.text, pairId: 4),
      MemoryCard(id: 9, content: 'Twinkle', type: CardType.text, pairId: 4),
    ];
    
    cards.shuffle();
    setState(() {
      _cards = cards;
    });
  }

  void _onCardTapped(int index) {
    if (_isChecking || 
        _matchedIndices.contains(index) || 
        _flippedIndices.contains(index) ||
        _flippedIndices.length >= 2) {
      return;
    }

    setState(() {
      _flippedIndices.add(index);
    });

    if (_flippedIndices.length == 2) {
      _checkForMatch();
    }
  }

  Future<void> _checkForMatch() async {
    setState(() {
      _isChecking = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    int firstIndex = _flippedIndices[0];
    int secondIndex = _flippedIndices[1];

    if (_cards[firstIndex].pairId == _cards[secondIndex].pairId) {
      // Match found!
      setState(() {
        _matchedIndices.add(firstIndex);
        _matchedIndices.add(secondIndex);
        _matchesFound++;
      });

      // Brief pause to show the match
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if game is complete
      if (_matchesFound == _totalPairs) {
        await Future.delayed(const Duration(milliseconds: 500));
        _onGameComplete();
      }
    }

    setState(() {
      _flippedIndices.clear();
      _isChecking = false;
    });
  }

  Future<void> _onGameComplete() async {
    // Stop the timer
    _stopwatch.stop();
    _timer.cancel();
    
    // Only award tokens if not in replay mode
    if (!widget.isReplay) {
      await _addToken();
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.red[700]!,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white, width: 3),
          ),
          content: Text(
            widget.isReplay
                ? 'Excellent memory!\nYou found all the pairs!\n\nTime: $_elapsedTime'
                : 'Excellent memory!\nYou found all the pairs!\n\nTime: $_elapsedTime\n\nYou get one token!\nYou now have a total of $_currentTokens tokens!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: const Text('The Memory Challenge'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Match the musical pairs!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB22222),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[900]!, width: 2),
                    ),
                    child: Text(
                      'Matches: $_matchesFound / $_totalPairs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[900]!, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, color: Colors.red[900], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _elapsedTime,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    bool isFlipped = _flippedIndices.contains(index) || 
                                     _matchedIndices.contains(index);
                    bool isMatched = _matchedIndices.contains(index);

                    return GestureDetector(
                      onTap: () => _onCardTapped(index),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: isFlipped
                            ? _buildCardFront(_cards[index], isMatched)
                            : _buildCardBack(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      key: const ValueKey('back'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[700]!, Colors.red[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 50,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildCardFront(MemoryCard card, bool isMatched) {
    return Container(
      key: ValueKey('front-${card.id}'),
      decoration: BoxDecoration(
        color: isMatched ? Colors.green[400] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMatched ? Colors.green[700]! : Colors.red[700]!,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          card.content,
          style: TextStyle(
            fontSize: card.type == CardType.emoji ? 50 : 24,
            fontWeight: FontWeight.bold,
            color: isMatched ? Colors.white : Colors.red[900],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

enum CardType {
  text,
  emoji,
}

class MemoryCard {
  final int id;
  final String content;
  final CardType type;
  final int pairId;

  MemoryCard({
    required this.id,
    required this.content,
    required this.type,
    required this.pairId,
  });
}