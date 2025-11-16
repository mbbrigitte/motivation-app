import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/storage_service.dart';
import 'knight_advancer.dart';

class TreasureChestPage extends StatefulWidget {
  const TreasureChestPage({super.key});

  @override
  _TreasureChestPageState createState() => _TreasureChestPageState();
}

class _TreasureChestPageState extends State<TreasureChestPage> {
  int _currentTokens = 0;
  int _currentPoints = 0; // NEW: track points
  bool _isLoading = true;
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;

  final List<Map<String, dynamic>> _quests = [
    {'name': '⏱️ 15 minute practice', 'tokens': 3},
    {'name': '⏱️ 30 minute practice', 'tokens': 6},
    {'name': '⭐ Self-motivated hero', 'tokens': 1},
    {'name': '🎯 Practice scale with goal setting', 'tokens': 1},
    {'name': '🎵 Listen to Suzuki songs', 'tokens': 1},
  ];

  @override
  void initState() {
    super.initState();
    _loadTokens();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset(
      'assets/videos/Hailuo_treasure_chest_open_closes.mp4',
    );
    
    await _videoController.initialize();
    await _videoController.setLooping(false);
    
    // Seek to 0.5 seconds for the still frame
    await _videoController.seekTo(const Duration(milliseconds: 500));
    await _videoController.pause();
    
    // Add listener to detect when video ends
    _videoController.addListener(_videoListener);
    
    setState(() {
      _isVideoInitialized = true;
    });
  }

  void _videoListener() {
    if (_videoController.value.position >= _videoController.value.duration &&
        _isPlaying) {
      setState(() {
        _isPlaying = false;
      });
      // Return to still frame at 0.5s
      _videoController.seekTo(const Duration(milliseconds: 500));
      _videoController.pause();
    }
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _loadTokens() async {
    int tokens = await StorageService.loadTokens();
    int points = await StorageService.loadPoints(); // NEW: load points
    setState(() {
      _currentTokens = tokens;
      _currentPoints = points; // NEW
      _isLoading = false;
    });
  }

  Future<void> _collectTokens(int amount) async {
    // Play video animation
    if (_isVideoInitialized && !_isPlaying) {
      setState(() {
        _isPlaying = true;
      });
      
      // Start from beginning
      await _videoController.seekTo(Duration.zero);
      await _videoController.play();
    }
    
    setState(() {
      _currentTokens += amount;
      _currentPoints += amount; // NEW: points also increase
    });
    
    // Save to storage
    await StorageService.saveTokens(_currentTokens);
    
    // Update total tokens ever
    int totalTokens = await StorageService.loadTotalTokens();
    await StorageService.saveTotalTokens(totalTokens + amount);
    
    // NEW: Update points (lifetime achievement)
    await StorageService.addPoints(amount);
  }

  void _navigateToKnightScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KnightAdvancer(),
      ),
    );
  }

  void _showRedeemDialog() {
    final options = [5, 10, 50, 250];

    showDialog(
      context: context,
      builder: (context) {
        int availableTokens = _currentTokens;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.yellow[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.orange[900]!, width: 3),
              ),
              title: Row(
                children: [
                  Icon(Icons.circle, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Available: $availableTokens tokens',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 300,
                height: 180,
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.0,
                  shrinkWrap: true,
                  children: options.map((val) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: availableTokens >= val
                          ? () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Redeem $val tokens?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(ctx); // close confirmation
                                        
                                        // Update tokens - properly decrease the count
                                        int newTokenCount = _currentTokens - val;
                                        
                                        // Update dialog state
                                        setDialogState(() {
                                          availableTokens = newTokenCount;
                                        });
                                        
                                        // Update main page state
                                        setState(() {
                                          _currentTokens = newTokenCount;
                                          // Points stay the same - they never decrease!
                                        });
                                        
                                        // Save updated tokens
                                        await StorageService.saveTokens(_currentTokens);
                                        
                                        // CRITICAL: Clear knight's saved position
                                        // so it recalculates on next load
                                        await StorageService.clearKnightPosition();
                                      },
                                      child: const Text('Confirm'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Redeem $val'),
                          const SizedBox(width: 5),
                          Icon(Icons.circle, color: Colors.amber, size: 16),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuestButton(Map<String, dynamic> quest) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => _collectTokens(quest['tokens']),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              quest['name'],
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.yellow[600],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+${quest['tokens']} tokens',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.yellow[800],
      appBar: AppBar(
        title: const Center(
          child: Text(
            "⚔️ Knight's Treasure Quest ⚔️",
            style: TextStyle(fontSize: 26),
          ),
        ),
        backgroundColor: Colors.red[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // NEW: Points display (lifetime achievement)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[300]!, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Total Points: $_currentPoints',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Token counter with icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, color: Colors.amber, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Tokens: $_currentTokens / 250',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Progress bar
                  Container(
                    width: double.infinity,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.brown[800],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange[900]!, width: 3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          LinearProgressIndicator(
                            value: _currentTokens / 250,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.amber[600]!,
                            ),
                            minHeight: 30,
                          ),
                          Center(
                            child: Text(
                              '${((_currentTokens / 250) * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                shadows: [
                                  Shadow(
                                    blurRadius: 2,
                                    color: Colors.black,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Video treasure chest
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.brown[700],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange[900]!, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: _isVideoInitialized
                          ? AspectRatio(
                              aspectRatio: _videoController.value.aspectRatio,
                              child: VideoPlayer(_videoController),
                            )
                          : const Center(
                              child: CircularProgressIndicator(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showRedeemDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Redeem Tokens'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _navigateToKnightScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("View Knight's Journey"),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Add spacing to align with the token progress bar
                  const SizedBox(height: 150), // Moved down a bit more
                  
                  ..._quests.map((quest) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildQuestButton(quest),
                  )).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}