import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/storage_service.dart';
import 'practice_finished.dart';

class InstrumentChallenge extends StatefulWidget {
  final bool isReplay;
  
  const InstrumentChallenge({super.key, this.isReplay = false});

  @override
  State<InstrumentChallenge> createState() => _InstrumentChallengeState();
}

class PuzzlePiece {
  final int row;
  final int col;
  bool isPlaced;

  PuzzlePiece({
    required this.row,
    required this.col,
    this.isPlaced = false,
  });
}

class ViolinLabel {
  final String name;
  final double topPercent;
  final bool isLeft;

  ViolinLabel({
    required this.name,
    required this.topPercent,
    required this.isLeft,
  });
}

class _InstrumentChallengeState extends State<InstrumentChallenge> {
  static const int rows = 4;
  static const int cols = 2;
  
  List<PuzzlePiece> pieces = [];
  bool isCompleted = false;
  bool _buttonPressed = false;
  int _currentTokens = 0;
  bool showLabelChallenge = false;
  bool showLabelLearning = false;
  Map<String, bool> labelPlacements = {};

  final List<ViolinLabel> violinLabels = [
    ViolinLabel(name: 'Scroll', topPercent: 0.08, isLeft: false),
    ViolinLabel(name: 'Tuning Pegs', topPercent: 0.17, isLeft: true),
    ViolinLabel(name: 'Fingerboard', topPercent: 0.34, isLeft: false),
    ViolinLabel(name: 'Strings', topPercent: 0.48, isLeft: true),
    ViolinLabel(name: 'Body', topPercent: 0.68, isLeft: false),
    ViolinLabel(name: 'Bridge', topPercent: 0.70, isLeft: true),
  ];

  @override
  void initState() {
    super.initState();
    _loadTokens();
    _initializePuzzle();
    // Initialize label placements
    for (var label in violinLabels) {
      labelPlacements[label.name] = false;
    }
    
    // Unlock this challenge when first accessed (not in replay mode)
    if (!widget.isReplay) {
      StorageService.unlockChallenge('instrument_challenge');
    }
  }

  Future<void> _loadTokens() async {
    int tokens = await StorageService.loadTokens();
    setState(() {
      _currentTokens = tokens;
    });
  }

  void _initializePuzzle() {
    pieces.clear();
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        pieces.add(PuzzlePiece(row: row, col: col));
      }
    }
    pieces.shuffle();
    isCompleted = false;
  }

  void _checkCompletion() {
    if (showLabelChallenge) {
      // Check if all labels are placed
      bool allLabelsPlaced = labelPlacements.values.every((placed) => placed);
      if (allLabelsPlaced && !_buttonPressed) {
        setState(() {
          _buttonPressed = true;
        });
        _onLabelChallengeComplete();
      }
    } else {
      // Check if all puzzle pieces are placed
      bool allPlaced = pieces.every((piece) => piece.isPlaced);
      if (allPlaced && !isCompleted && !_buttonPressed) {
        setState(() {
          isCompleted = true;
          _buttonPressed = true;
        });
        _onPuzzleComplete();
      }
    }
  }

  Future<void> _onPuzzleComplete() async {
    // Only award tokens if not in replay mode
    if (!widget.isReplay) {
      await _addToken();
    }

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.green[700]!,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white, width: 3),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isReplay
                    ? 'Excellent! Well done!'
                    : 'Well done! You receive one token!\nYou now have a total of $_currentTokens tokens!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Do you want an extra challenge?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PracticeFinished()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'No',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  showLabelLearning = true;
                  _buttonPressed = false;
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green[900],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Yes!',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _onLabelChallengeComplete() async {
    // Only award tokens if not in replay mode
    if (!widget.isReplay) {
      await _addToken();
    }

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.green[700]!,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white, width: 3),
          ),
          content: Text(
            widget.isReplay
                ? 'Excellent! Well done!'
                : 'Excellent! You earned another token!\nYou now have a total of $_currentTokens tokens!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PracticeFinished()),
        );
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

  // Helper method to get line length for each label
  double _getLineLength(String labelName) {
    switch (labelName) {
      case 'Scroll':
        return 100.0; // Much longer
      case 'Tuning Pegs':
        return 95.0; // Much longer
      case 'Fingerboard':
        return 95.0; // Much longer
      case 'Strings':
        return 90.0; // Perfect - no change
      case 'Body':
        return 85.0; // Longer
      case 'Bridge':
        return 85.0; // Perfect - no change
      default:
        return 60.0;
    }
  }

  // Helper method to get label offset (move closer to center)
  double _getLabelOffset(String labelName) {
    switch (labelName) {
      case 'Scroll':
        return 90.0; // Move more left towards center (30 + 30)
      case 'Fingerboard':
        return 120.0; // Move more left towards center (30 + 30)
      case 'Body':
        return 60.0; // Move more left towards center (30 + 30)
      default:
        return 0.0; // No offset
    }
  }

  // Helper method to get left-side label offset (move towards center)
  double _getLeftLabelOffset(String labelName) {
    switch (labelName) {
      case 'Strings':
        return 11.0; // Move right towards center (negative = move right)
      default:
        return 0.0; // No offset
    }
  }

  // Helper method to get vertical offset adjustment
  double _getVerticalOffset(String labelName) {
    switch (labelName) {
      case 'Bridge':
        return 5.0; // Move down
       case 'Fingerboard':
        return -50.0; // Move up
        case 'Scroll':
        return -5.0; // Move up
    default:
        return 0.0; // No offset
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final violinWidth = screenWidth * 0.35;
    final violinHeight = violinWidth * 2.5;

    final pieceWidth = violinWidth / cols;
    final pieceHeight = violinHeight / rows;

    if (showLabelChallenge) {
      return _buildLabelChallenge(screenWidth, screenHeight, violinWidth, violinHeight);
    }

    if (showLabelLearning) {
      return _buildLabelLearning(screenWidth, screenHeight, violinWidth, violinHeight);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: const Text('The Instrument Challenge'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            if (!isCompleted)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Drag the puzzle pieces to the right spot to create a violin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Center(
              child: Container(
                width: screenWidth * 0.9,
                height: violinHeight + 100,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: SizedBox(
                        width: violinWidth,
                        height: violinHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Opacity(
                              opacity: 0.15,
                              child: Image.asset(
                                'assets/images/kind_violin.png',
                                width: violinWidth,
                                height: violinHeight,
                                fit: BoxFit.contain,
                              ),
                            ),

                            ...List.generate(rows * cols, (index) {
                              final row = index ~/ cols;
                              final col = index % cols;
                              final piece = pieces.firstWhere(
                                (p) => p.row == row && p.col == col,
                              );

                              return Positioned(
                                left: col * pieceWidth,
                                top: row * pieceHeight,
                                child: DragTarget<PuzzlePiece>(
                                  onWillAccept: (data) => data?.row == row && data?.col == col,
                                  onAccept: (data) {
                                    setState(() {
                                      data.isPlaced = true;
                                      _checkCompletion();
                                    });
                                  },
                                  builder: (context, candidateData, rejectedData) {
                                    return Container(
                                      width: pieceWidth,
                                      height: pieceHeight,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: piece.isPlaced
                                              ? Colors.green.withOpacity(0.3)
                                              : Colors.grey.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: piece.isPlaced
                                          ? ClipRect(
                                              child: OverflowBox(
                                                alignment: Alignment(
                                                  -1 + (2 * col / (cols - 1)),
                                                  -1 + (2 * row / (rows - 1)),
                                                ),
                                                maxWidth: violinWidth,
                                                maxHeight: violinHeight,
                                                child: Image.asset(
                                                  'assets/images/kind_violin.png',
                                                  width: violinWidth,
                                                  height: violinHeight,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            )
                                          : null,
                                    );
                                  },
                                ),
                              );
                            }),

                            ...violinLabels.map((label) {
                              final labelTop = violinHeight * label.topPercent;
                              final lineLength = _getLineLength(label.name);
                              // Adjust label position based on which label it is
                              final labelOffset = _getLabelOffset(label.name);
                              final leftLabelOffset = _getLeftLabelOffset(label.name);
                              final verticalOffset = _getVerticalOffset(label.name);
                              final labelX = label.isLeft 
                                  ? -130.0 + leftLabelOffset 
                                  : violinWidth + 10 - labelOffset;

                              return Positioned(
                                left: labelX,
                                top: labelTop - 12 + verticalOffset,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!label.isLeft)
                                      CustomPaint(
                                        size: Size(lineLength, 24),
                                        painter: _LinePainter(),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        label.name,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    if (label.isLeft)
                                      CustomPaint(
                                        size: Size(lineLength, 24),
                                        painter: _LinePainter(),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (!isCompleted)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: pieces.where((p) => !p.isPlaced).map((piece) {
                    return Draggable<PuzzlePiece>(
                      data: piece,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: pieceWidth,
                          height: pieceHeight,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment(
                                -1 + (2 * piece.col / (cols - 1)),
                                -1 + (2 * piece.row / (rows - 1)),
                              ),
                              maxWidth: violinWidth,
                              maxHeight: violinHeight,
                              child: Image.asset(
                                'assets/images/kind_violin.png',
                                width: violinWidth,
                                height: violinHeight,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: Container(
                          width: pieceWidth,
                          height: pieceHeight,
                          color: Colors.grey[300],
                        ),
                      ),
                      child: Container(
                        width: pieceWidth,
                        height: pieceHeight,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment(
                              -1 + (2 * piece.col / (cols - 1)),
                              -1 + (2 * piece.row / (rows - 1)),
                            ),
                            maxWidth: violinWidth,
                            maxHeight: violinHeight,
                            child: Image.asset(
                              'assets/images/kind_violin.png',
                              width: violinWidth,
                              height: violinHeight,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelLearning(double screenWidth, double screenHeight, double violinWidth, double violinHeight) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: const Text('Learn the Violin Parts'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Do you know all the parts of the violin?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                final violinTopOffset = (availableHeight - violinHeight) / 2;
                
                return Center(
                  child: Container(
                    width: screenWidth * 0.9,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: (screenWidth * 0.9 - violinWidth) / 2,
                          top: violinTopOffset,
                          child: Image.asset(
                            'assets/images/kind_violin.png',
                            width: violinWidth,
                            height: violinHeight,
                            fit: BoxFit.contain,
                          ),
                        ),

                        ...violinLabels.map((label) {
                          final centerX = (screenWidth * 0.9) / 2;
                          final labelTop = violinTopOffset + (violinHeight * label.topPercent);
                          final lineLength = _getLineLength(label.name);
                          final labelOffset = _getLabelOffset(label.name);
                          final leftLabelOffset = _getLeftLabelOffset(label.name);
                          final verticalOffset = _getVerticalOffset(label.name);
                          
                          // Keep labels closer - don't subtract/add lineLength
                          final double targetLeft;
                          if (label.isLeft) {
                            targetLeft = centerX - (violinWidth / 2) - 130 + leftLabelOffset;
                          } else {
                            targetLeft = centerX + (violinWidth / 2) + 10 - labelOffset;
                          }

                          return Positioned(
                            left: targetLeft,
                            top: labelTop - 15 + verticalOffset,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!label.isLeft)
                                  CustomPaint(
                                    size: Size(lineLength, 30),
                                    painter: _LinePainter(),
                                  ),
                                Container(
                                  width: 110,
                                  height: 30,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      label.name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                if (label.isLeft)
                                  CustomPaint(
                                    size: Size(lineLength, 30),
                                    painter: _LinePainter(),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  showLabelLearning = false;
                  showLabelChallenge = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Yes, I know them!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelChallenge(double screenWidth, double screenHeight, double violinWidth, double violinHeight) {
    final shuffledLabels = List<ViolinLabel>.from(violinLabels)..shuffle();

    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: const Text('Label Challenge'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Drag the labels to their correct label spot',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                final violinTopOffset = (availableHeight - violinHeight) / 2;
                
                return Center(
                  child: Container(
                    width: screenWidth * 0.9,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: (screenWidth * 0.9 - violinWidth) / 2,
                          top: violinTopOffset,
                          child: Image.asset(
                            'assets/images/kind_violin.png',
                            width: violinWidth,
                            height: violinHeight,
                            fit: BoxFit.contain,
                          ),
                        ),

                        ...violinLabels.map((label) {
                          final centerX = (screenWidth * 0.9) / 2;
                          final labelTop = violinTopOffset + (violinHeight * label.topPercent);
                          final lineLength = _getLineLength(label.name);
                          final labelOffset = _getLabelOffset(label.name);
                          final leftLabelOffset = _getLeftLabelOffset(label.name);
                          final verticalOffset = _getVerticalOffset(label.name);
                          
                          // Keep labels closer - don't subtract/add lineLength
                          final double targetLeft;
                          if (label.isLeft) {
                            targetLeft = centerX - (violinWidth / 2) - 130 + leftLabelOffset;
                          } else {
                            targetLeft = centerX + (violinWidth / 2) + 10 - labelOffset;
                          }

                          final isPlaced = labelPlacements[label.name] ?? false;

                          return Positioned(
                            left: targetLeft,
                            top: labelTop - 15 + verticalOffset,
                            child: DragTarget<String>(
                              onWillAccept: (data) {
                                print('onWillAccept: $data for ${label.name}, result: ${data == label.name}');
                                return data == label.name;
                              },
                              onAccept: (data) {
                                print('✓ onAccept: $data for ${label.name}');
                                setState(() {
                                  labelPlacements[data] = true;
                                  _checkCompletion();
                                });
                              },
                              builder: (context, candidateData, rejectedData) {
                                final bool isHovering = candidateData.isNotEmpty;
                                
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!label.isLeft)
                                      CustomPaint(
                                        size: Size(lineLength, 30),
                                        painter: _LinePainter(),
                                      ),
                                    Container(
                                      width: 110,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: isPlaced 
                                            ? Colors.green.withOpacity(0.5) 
                                            : (isHovering 
                                                ? Colors.blue.withOpacity(0.5) 
                                                : Colors.white.withOpacity(0.7)),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isPlaced 
                                              ? Colors.green 
                                              : (isHovering ? Colors.blue : Colors.grey[600]!),
                                          width: 3,
                                        ),
                                      ),
                                      child: Center(
                                        child: isPlaced
                                            ? Text(
                                                label.name,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                                textAlign: TextAlign.center,
                                              )
                                            : Text(
                                                '?',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                      ),
                                    ),
                                    if (label.isLeft)
                                      CustomPaint(
                                        size: Size(lineLength, 30),
                                        painter: _LinePainter(),
                                      ),
                                  ],
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: shuffledLabels.where((label) => !(labelPlacements[label.name] ?? false)).map((label) {
                return Draggable<String>(
                  data: label.name,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        label.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                  onDragStarted: () {
                    print('>>> Started dragging: ${label.name}');
                  },
                  onDragEnd: (details) {
                    print('>>> Ended dragging: ${label.name} wasAccepted=${details.wasAccepted}');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red[900],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      label.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB22222)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}