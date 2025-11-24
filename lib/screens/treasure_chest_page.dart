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
  int _currentPoints = 0;
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
      'assets/videos/dragon_on_chest.mp4',
    );

    await _videoController.initialize();
    await _videoController.setLooping(false);

    await _videoController.seekTo(const Duration(milliseconds: 500));
    await _videoController.pause();

    _videoController.addListener(_videoListener);

    setState(() => _isVideoInitialized = true);
  }

  void _videoListener() {
    if (_videoController.value.position >= _videoController.value.duration &&
        _isPlaying) {
      setState(() => _isPlaying = false);
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
    int points = await StorageService.loadPoints();
    setState(() {
      _currentTokens = tokens;
      _currentPoints = points;
      _isLoading = false;
    });
  }

  Future<void> _collectTokens(int amount) async {
    if (_isVideoInitialized && !_isPlaying) {
      setState(() => _isPlaying = true);
      await _videoController.seekTo(Duration.zero);
      await _videoController.play();
    }

    setState(() {
      _currentTokens += amount;
      _currentPoints += amount;
    });

    await StorageService.saveTokens(_currentTokens);

    int totalTokens = await StorageService.loadTotalTokens();
    await StorageService.saveTotalTokens(totalTokens + amount);

    await StorageService.addPoints(amount);
  }

  void _navigateToKnightScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KnightAdvancer()),
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
                width: double.maxFinite,
                height: 200,
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 2.1,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: options.map((val) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
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
                                        Navigator.pop(ctx);

                                        int newCount =
                                            _currentTokens - val;

                                        setDialogState(() {
                                          availableTokens = newCount;
                                        });

                                        setState(() {
                                          _currentTokens = newCount;
                                        });

                                        await StorageService.saveTokens(
                                            newCount);
                                        await StorageService
                                            .clearKnightPosition();
                                      },
                                      child: const Text('Confirm'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          : null,
                      child: Text('Redeem $val'),
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () => _collectTokens(quest['tokens']),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              quest['name'],
              overflow: TextOverflow.visible,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.yellow[600],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+${quest['tokens']}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 650;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.yellow[800],
      appBar: AppBar(
        title: const Text(
          "⚔️ Knight's Treasure Quest ⚔️",
          style: TextStyle(fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.red[900],
      ),

      // EVERYTHING SCROLLS NOW
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isWide
              ? _buildWideLayout()
              : _buildStackedLayout(),
        ),
      ),
    );
  }

  /// 🖥️ Tablet / Web → Side-by-side layout
  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildLeftColumn()),
        const SizedBox(width: 24),
        Expanded(child: _buildRightColumn()),
      ],
    );
  }

  /// 📱 Phone → Stacked vertically
  Widget _buildStackedLayout() {
    return Column(
      children: [
        _buildRightColumn(),
        const SizedBox(height: 20),
        _buildLeftColumn(),
      ],
    );
  }

  /// LEFT SIDE
  Widget _buildLeftColumn() {
    return Column(
      children: [
        const SizedBox(height: 12),
        _buildTokenCounter(),
        const SizedBox(height: 12),
        _buildProgressBar(),
        const SizedBox(height: 20),
        _buildVideoBox(),
        const SizedBox(height: 20),
        _buildButtonsLeft(),
      ],
    );
  }

  /// RIGHT SIDE
  Widget _buildRightColumn() {
    return Column(
      children: _quests
          .map((quest) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildQuestButton(quest),
              ))
          .toList(),
    );
  }

 Widget _buildTokenCounter() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Tokens
      Icon(Icons.circle, color: Colors.amber, size: 22),
      const SizedBox(width: 8),
      Text(
        'Tokens: $_currentTokens / 250   |  ',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      // Achievements with little icon
      Icon(Icons.local_florist, color: Colors.green, size: 20),
      const SizedBox(width: 4),
      Text(
        'Points: $_currentPoints',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}

  Widget _buildProgressBar() {
    return Container(
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
    );
  }

  Widget _buildVideoBox() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxSize = constraints.maxWidth.clamp(160, 350);

        return SizedBox(
          width: maxSize,
          height: maxSize,
            child: _isVideoInitialized
                ? FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: Container(
                        color: Colors.transparent, // <-- Set the background color here
                        child: VideoPlayer(_videoController),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

 Widget _buildButtonsLeft() {
  return Row(
    children: [
      Expanded(
        child: ElevatedButton(
          onPressed: _showRedeemDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Redeem Tokens'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          onPressed: _navigateToKnightScreen,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("View Knight's Journey"),
        ),
      ),
    ],
  );
}
}
