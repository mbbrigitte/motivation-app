import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'knights_practice_timer.dart';

class ViolinTuner extends StatefulWidget {
  const ViolinTuner({super.key});

  @override
  State<ViolinTuner> createState() => _ViolinTunerState();
}

class _ViolinTunerState extends State<ViolinTuner>
    with TickerProviderStateMixin {
  static const platform =
      MethodChannel('com.flutter_testapplication.tuner/audio');

  static const Map<String, double> violinStrings = {
    'G': 196.00,
    'D': 293.66,
    'A': 440.00,
    'E': 659.26,
  };

  double currentPitch = 0.0;
  double currentAmplitude = 0.0;
  String currentString = '';
  double detuneAmount = 0.0;
  bool isInTune = false;
  bool isTooHigh = false;
  bool isTooLow = false;
  bool hasError = false;

  List<double> pitchBuffer = [];
  Timer? pitchTimer;
  late AnimationController needleController;

  // Dragon image is 832×540 px (landscape) — same aspect ratio logic as the
  // reference screen so the crown anchor is pixel-accurate on every device.
  static const double dragonAspectRatio = 832.0 / 540.0; // ≈ 1.541

  @override
  void initState() {
    super.initState();
    needleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _startRealTuning();
  }

  Future<void> _startRealTuning() async {
    setState(() {
      currentPitch = 0.0;
      currentAmplitude = 0.0;
      currentString = '';
      hasError = false;
    });

    try {
      await platform.invokeMethod('startListening');

      pitchTimer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
        if (!mounted) return;

        try {
          final result = await platform.invokeMethod('getPitch');
          if (result != null) {
            double pitch = result['pitch'] ?? 0.0;
            double amplitude = result['amplitude'] ?? 0.0;
            setState(() {
              currentAmplitude = amplitude;
              if (amplitude > 0.005) {
                currentPitch = _smoothPitch(pitch);
                _updateTuningState();
              }
            });
          }
        } catch (e) {
          print('Error getting pitch: $e');
          _showPermanentError();
        }
      });
    } catch (e) {
      print('❌ Error starting native audio: $e');
      _showPermanentError();
    }
  }

  void _showPermanentError() {
    if (!mounted) return;
    setState(() {
      hasError = true;
    });
  }

  double _smoothPitch(double pitch) {
    pitchBuffer.add(pitch);
    if (pitchBuffer.length > 5) pitchBuffer.removeAt(0);
    return pitchBuffer.reduce((a, b) => a + b) / pitchBuffer.length;
  }

  void _updateTuningState() {
    if (currentPitch < 150 || currentPitch > 800) {
      currentString = '';
      return;
    }

    double minDistance = double.infinity;
    String nearestString = '';
    double targetFreq = 0.0;

    violinStrings.forEach((stringName, frequency) {
      double distance = (currentPitch - frequency).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearestString = stringName;
        targetFreq = frequency;
      }
    });

    if (nearestString != currentString) {
      double halfDistance = _getHalfDistanceToNextString(nearestString);
      if (minDistance > halfDistance && pitchBuffer.length < 3) return;
    }

    currentString = nearestString;

    detuneAmount = 1200 * log(currentPitch / targetFreq) / log(2);
    detuneAmount = detuneAmount.clamp(-50.0, 50.0);

    isInTune = detuneAmount.abs() < 5;
    isTooHigh = detuneAmount > 5;
    isTooLow = detuneAmount < -5;

    needleController.animateTo(
      (detuneAmount + 50) / 100,
      duration: const Duration(milliseconds: 100),
    );
  }

  double _getHalfDistanceToNextString(String stringName) {
    final order = ['G', 'D', 'A', 'E'];
    int index = order.indexOf(stringName);
    if (index < 0 || index >= order.length - 1) return 50;

    double current = violinStrings[stringName]!;
    double next = violinStrings[order[index + 1]]!;
    return (next - current) / 2;
  }

  Future<void> _stopAudio() async {
    pitchTimer?.cancel();
    pitchTimer = null;
    try {
      await platform.invokeMethod('stopListening');
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  @override
  void dispose() {
    _stopAudio();
    needleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: Text(
          '🎻 Violin Tuner 🎻',
          style: TextStyle(fontSize: screenWidth * 0.065),
        ),
        backgroundColor: const Color(0xFFB22222),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Error banner ──────────────────────────────────────────────
            if (hasError)
              Container(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Audio system failed – Restart app',
                  style: TextStyle(color: Colors.white),
                ),
              ),

            // ── String name label ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.only(
                  top: screenHeight * 0.02, bottom: screenHeight * 0.005),
              child: Text(
                currentString.isNotEmpty
                    ? 'String: $currentString'
                    : 'Waiting...',
                style: TextStyle(
                  fontSize: screenWidth * 0.08,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFB22222),
                  fontFamily: 'Georgia',
                ),
              ),
            ),

            // ── Hz readout ────────────────────────────────────────────────
            Text(
              currentPitch > 0
                  ? '${currentPitch.toStringAsFixed(1)} Hz'
                  : '-- Hz',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                color: const Color(0xFF8B0000),
              ),
            ),

            // ── Needle gauge ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.only(
                top: screenHeight * 0.025,
                bottom: screenHeight * 0.01,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Cap at 70% of available width so it doesn't balloon on
                  // wide screens (same proportion as the original code).
                  final double gaugeSize =
                      (constraints.maxWidth * 0.70).clamp(0.0, 400.0);
                  return SizedBox(
                    width: gaugeSize,
                    height: gaugeSize * 0.5,
                    child: _buildNeedleGauge(gaugeSize),
                  );
                },
              ),
            ),

            // ── Dragon indicator ──────────────────────────────────────────
            Expanded(
              child: _buildDragonIndicator(),
            ),

            // ── "In tune!" message ────────────────────────────────────────
            SizedBox(
              height: screenHeight * 0.07,
              child: Center(
                child: AnimatedOpacity(
                  opacity: isInTune ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    'In tune!',
                    style: TextStyle(
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF228B22),
                    ),
                  ),
                ),
              ),
            ),

            // ── Continue to Practice button ───────────────────────────────
            Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.025),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KnightsPracticeTimer(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF228B22),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                    horizontal: screenWidth * 0.1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    side: const BorderSide(
                        color: Color.fromARGB(99, 168, 158, 145), width: 3),
                  ),
                  elevation: 6,
                ),
                child: Text(
                  'Continue to Practice →',
                  style: TextStyle(
                      fontSize: screenWidth * 0.055,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // ── Listening indicator ───────────────────────────────────────
            if (!hasError && currentAmplitude < 0.005)
              Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: screenHeight * 0.01),
                    const Text(
                      'Ready to detect violin...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Needle gauge ────────────────────────────────────────────────────────────
  Widget _buildNeedleGauge(double size) {
    final double centerPinSize = size * 0.07;
    final double needleThickness = size * 0.018;

    return ClipPath(
      clipper: HalfCircleClipper(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD580),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF8B4513), width: size * 0.018),
            ),
            child: CustomPaint(
              painter: GaugePainter(),
            ),
          ),

          // Center reference line (green = in-tune target)
          Container(
            width: needleThickness,
            height: size * 0.45,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 117, 184, 9),
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          // Rotating needle
          AnimatedBuilder(
            animation: needleController,
            builder: (context, child) {
              return Transform.rotate(
                angle: (needleController.value - 0.5) * pi,
                child: Container(
                  width: needleThickness * 1.93,
                  height: size * 0.45,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),

          // Center pin
          Container(
            width: centerPinSize,
            height: centerPinSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF8B4513), width: centerPinSize * 0.2),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dragon indicator ─────────────────────────────────────────────────────────
  Widget _buildDragonIndicator() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;

        // Dragon image is landscape (832×540). Under BoxFit.fill the rendered
        // size equals the Positioned widget's size, so we compute it the same
        // way the reference does: constrain by width first.
        final double renderedWidth = availableWidth;
        final double renderedHeight = availableWidth / dragonAspectRatio;

        // Dragon sits at the bottom of the Expanded area.
        const double dragonLeft = 0.0;
        final double dragonTop =
            availableHeight - renderedHeight + renderedHeight * 0.1;

        // Crown anchored above the dragon's head.
        // dragonHeadFraction: how far from the TOP of the image the head sits.
        // The dragon's head is roughly 45% down the image.
        const double dragonHeadFraction = 0.25;
        final double headY = dragonTop + renderedHeight * dragonHeadFraction;

        // Crown sized relative to rendered height — keep it modest.
        final double crownSize = renderedHeight * 0.30;
        final double travelWidth = availableWidth - crownSize;
        final double normalized = (detuneAmount + 50) / 100;
        final double crownX = normalized * travelWidth;

        // Crown sits higher — full crownSize above head, plus an extra nudge up.
        final double verticalDrop = isInTune ? renderedHeight * 0.04 : 0.0;
        final double crownTop = headY - crownSize - renderedHeight * 0.05 + verticalDrop;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Dragon drawn first (bottom of stack), cropped 15% top + bottom
            Positioned(
              left: dragonLeft,
              top: dragonTop,
              width: renderedWidth,
              height: renderedHeight,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.center,
                  heightFactor: 0.70, // show middle 70% = crop 15% each side
                  child: Image.asset(
                    'assets/images/Gemini_dragon_tuned.webp',
                    width: renderedWidth,
                    fit: BoxFit.fitWidth,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.pets, size: 100, color: Colors.white),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Crown drawn on top of the dragon
            AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              top: crownTop,
              left: crownX,
              child: Image.asset(
                'assets/images/crown_transparent.png',
                width: crownSize,
                height: crownSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.star, size: crownSize, color: Colors.yellow);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Supporting painters / clippers ───────────────────────────────────────────

class GaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.01;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - (size.width * 0.05);

    paint.color = Colors.green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi + pi / 3,
      pi / 3,
      false,
      paint,
    );

    final linePaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = size.width * 0.01;
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy - radius + (size.width * 0.05)),
      linePaint,
    );

    final double fontSize = size.width * 0.06;
    final textStyle = TextStyle(fontSize: fontSize, color: Colors.white);

    TextPainter(
      text: TextSpan(text: 'LOW', style: textStyle),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas,
          Offset(center.dx - (size.width * 0.4), center.dy - (size.height * 0.3)));

    TextPainter(
      text: TextSpan(text: 'HIGH', style: textStyle),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas,
          Offset(center.dx + (size.width * 0.27), center.dy - (size.height * 0.3)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HalfCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height / 2));
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}