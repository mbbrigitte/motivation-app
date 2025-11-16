import 'dart:async';
import 'dart:math';
import 'dart:ui'; 
import 'package:flutter/material.dart';

class TreasureChest extends StatefulWidget {
  final int initialTokens;
  final int totalPoints; // NEW: lifetime points

  const TreasureChest({
    super.key, 
    this.initialTokens = 0,
    this.totalPoints = 0, // NEW parameter
  });

  @override
  TreasureChestState createState() => TreasureChestState();
}

class TreasureChestState extends State<TreasureChest> with TickerProviderStateMixin {
  int _currentTokens = 0;
  int _currentPoints = 0; // NEW: track points
  final List<_FlyingCoin> _coins = [];

  final double chestWidth = 180;
  final double chestHeight = 120;

  @override
  void initState() {
    super.initState();
    _currentTokens = widget.initialTokens;
    _currentPoints = widget.totalPoints;
  }

  void addTokens(int count) {
    setState(() {
      _currentTokens += count;
      _currentPoints += count; // Points also increase
    });

    // Animate coins flying in
    for (int i = 0; i < count; i++) {
      final animation = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );

      final startX = Random().nextDouble() * 150;
      final startY = -50.0;
      final endX = 10 + Random().nextDouble() * (chestWidth - 20);
      final endY = 20 + Random().nextDouble() * (chestHeight - 40);

      final flyingCoin = _FlyingCoin(
        animation: animation,
        startX: startX,
        startY: startY,
        endX: endX,
        endY: endY,
      );

      animation.addListener(() {
        setState(() {});
      });

      animation.forward().then((_) {
        animation.dispose();
        setState(() {
          _coins.remove(flyingCoin);
        });
      });

      _coins.add(flyingCoin);
    }
  }

  void removeTokens(int count) {
    setState(() {
      _currentTokens = max(0, _currentTokens - count);
      // Points stay the same - they never decrease!
    });
  }

  // Getter for current points (useful for parent widgets)
  int get currentPoints => _currentPoints;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Points display (lifetime achievement)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue[300]!, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Total Points: $_currentPoints',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Tokens display (redeemable coins)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange[700],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange[300]!, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🪙',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'Tokens: $_currentTokens',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Treasure chest with coins
        SizedBox(
          width: chestWidth,
          height: chestHeight + 40, // space for flying coins
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Chest base
              Positioned(
                bottom: 0,
                child: Container(
                  width: chestWidth,
                  height: chestHeight,
                  decoration: BoxDecoration(
                    color: Colors.brown[700],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26, offset: Offset(3, 3), blurRadius: 4)
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Wooden planks
                      for (int i = 0; i < 5; i++)
                        Positioned(
                          top: i * 20.0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 4,
                            color: Colors.brown[500],
                          ),
                        ),
                      // Golden lock
                      Positioned(
                        bottom: 10,
                        left: chestWidth / 2 - 12,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange[800]!, width: 2),
                          ),
                        ),
                      ),
                      // Tokens inside chest (visual representation)
                      for (int i = 0; i < min(_currentTokens, 40); i++) // Cap visual coins at 40
                        Positioned(
                          left: 10 + (i % 8) * 18,
                          bottom: 10 + ((i ~/ 8) * 18),
                          child: _drawCoin(size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              // Flying coins
              for (var coin in _coins)
                Positioned(
                  left: lerpDouble(coin.startX, coin.endX,
                      coin.animation.value)!, // animate X
                  top: lerpDouble(coin.startY, coin.endY,
                      coin.animation.value)!, // animate Y
                  child: _drawCoin(size: 18),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _drawCoin({double size = 20}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Colors.yellow, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.amber[800]!, width: 2),
      ),
      child: Center(
        child: Text(
          '🪙',
          style: TextStyle(fontSize: size * 0.6),
        ),
      ),
    );
  }
}

class _FlyingCoin {
  final AnimationController animation;
  final double startX;
  final double startY;
  final double endX;
  final double endY;

  _FlyingCoin({
    required this.animation,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });
}