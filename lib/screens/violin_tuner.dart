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
  // METHOD CHANNEL - connects to native code
  static const platform = MethodChannel('com.flutter_testapplication.tuner/audio');
  
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

  List<double> pitchBuffer = [];
  Timer? pitchTimer;
  late AnimationController needleController;

  double simulatedPitch = 440.0;
  String currentSimulatedString = 'A';
  Random random = Random();

  @override
  void initState() {
    super.initState();
    needleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _startAudio();
  }

  // START NATIVE AUDIO PROCESSING
  Future<void> _startAudio() async {
    try {
      // Start listening on native side
      await platform.invokeMethod('startListening');
      print('✅ Native audio started successfully');
      
      // Poll for pitch data
      pitchTimer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
        try {
          final result = await platform.invokeMethod('getPitch');
          
          if (result != null) {
            double pitch = result['pitch'] ?? 0.0;
            double amplitude = result['amplitude'] ?? 0.0;
            
            setState(() {
              currentAmplitude = amplitude;
              
              if (amplitude > 0.005) { // Only process if loud enough
                currentPitch = _smoothPitch(pitch);
                _updateTuningState();
              }
            });
          }
        } catch (e) {
          print('Error getting pitch: $e');
        }
      });
    } catch (e) {
      print('❌ Error starting native audio: $e');
      print('Falling back to simulation mode');
      _startSimulationFallback();
    }
  }

  // FALLBACK: Simulation mode (if native code fails)
  void _startSimulationFallback() {
    pitchTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        simulatedPitch += (random.nextDouble() - 0.5) * 10;

        if (currentSimulatedString == 'G') {
          simulatedPitch = simulatedPitch.clamp(180.0, 210.0);
        } else if (currentSimulatedString == 'D') {
          simulatedPitch = simulatedPitch.clamp(280.0, 310.0);
        } else if (currentSimulatedString == 'A') {
          simulatedPitch = simulatedPitch.clamp(430.0, 450.0);
        } else if (currentSimulatedString == 'E') {
          simulatedPitch = simulatedPitch.clamp(645.0, 675.0);
        }

        currentAmplitude = 0.05 + random.nextDouble() * 0.02;
        currentPitch = _smoothPitch(simulatedPitch);
        _updateTuningState();
      });
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
    currentSimulatedString = nearestString;

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

  void _changeString(String string) {
    currentSimulatedString = string;
    simulatedPitch =
        violinStrings[string]! + (random.nextDouble() - 0.5) * 20;
  }

  @override
  void dispose() {
    pitchTimer?.cancel();
    needleController.dispose();
    try {
      platform.invokeMethod('stopListening');
    } catch (e) {
      print('Error stopping audio: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: const Text(
          '🎻 Violin Tuner 🎻',
          style: TextStyle(fontSize: 26),
        ),
        backgroundColor: const Color(0xFFB22222),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                Text(
                  currentString.isNotEmpty
                      ? 'String: $currentString'
                      : 'Waiting...',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB22222),
                    fontFamily: 'Georgia',
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  currentPitch > 0
                      ? '${currentPitch.toStringAsFixed(1)} Hz'
                      : '-- Hz',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF8B0000),
                  ),
                ),

                const SizedBox(height: 40),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final double gaugeSize = constraints.maxWidth * 0.3; 
                    return SizedBox(
                      width: gaugeSize,
                      height: gaugeSize,
                      child: _buildNeedleGauge(gaugeSize),
                    );
                  },
                ),

                const SizedBox(height: 50),

                _buildDragonIndicator(),

                const SizedBox(height: 40),

                // In Tune Indicator
                if (isInTune)
                  Text(
                    'In tune!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF228B22),
                    ),
                  ),

                const SizedBox(height: 40),

                _buildDemoControls(),

                const SizedBox(height: 20),

                Text(
                  'Web Demo: Simulated pitch data for testing UI/UX',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const KnightsPracticeTimer(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF228B22),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                      side: const BorderSide(
                          color: Color.fromARGB(99, 168, 158, 145),
                          width: 3),
                    ),
                    elevation: 6,
                  ),
                  child: const Text(
                    'Continue to Practice →',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NEEDLE GAUGE (RESPONSIVE)
  Widget _buildNeedleGauge(double size) {
    final double centerPinSize = size * 0.07;
    final double needleThickness = size * 0.018;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD580),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF8B4513), width: size * 0.018),
          ),
          child: CustomPaint(
            painter: GaugePainter(),
          ),
        ),

        // Center reference line (amber)
        Transform.rotate(
          angle: 0,
          child: Container(
            width: needleThickness,
            height: size * 0.45,
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),

        // Rotating needle
        AnimatedBuilder(
          animation: needleController,
          builder: (context, child) {
            return Transform.rotate(
              angle: (needleController.value - 0.5) * pi,
              child: Container(
                width: needleThickness * 1.3,
                height: size * 0.45,
                decoration: BoxDecoration(
                  color: Colors.white,
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
            border: Border.all(color: const Color(0xFF8B4513), width: centerPinSize * 0.2),
          ),
        ),
      ],
    );
  }

  // DRAGON INDICATOR
  Widget _buildDragonIndicator() {
    double normalized = (detuneAmount + 50) / 100;
    double verticalDrop = isInTune ? 10 : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double dragonHeight = maxWidth * 0.5;
        final double crownSize = maxWidth * 0.15;
        final double crownX = 20 + normalized * (maxWidth - 40 - crownSize);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: maxWidth,
              height: dragonHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.center,
                        heightFactor: 0.55,
                        child: Image.asset(
                          "assets/images/Gemini_dragon_tuned.png",
                          width: maxWidth,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    top: verticalDrop - 50,
                    left: crownX,
                    child: Image.asset(
                      "assets/images/crown_transparent.png",
                      width: crownSize,
                      height: crownSize,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // STATUS DISPLAY
  Color _getTuningStatusColor() {
    if (isInTune) return const Color(0xFF228B22);
    if (isTooHigh) return const Color.fromARGB(255, 218, 190, 32);
    if (isTooLow) return const Color.fromARGB(255, 218, 190, 32);
    return Colors.grey[700]!;
  }

  String _getTuningStatusText() {
    if (currentAmplitude < 0.005) return 'Play the string...';
    if (currentString.isEmpty) return 'Out of range';
    if (isInTune) return '✓ In Tune!';
    if (isTooHigh) return 'Tuning';
    if (isTooLow) return 'Tuning';
    return '';
  }

  // DEMO CONTROLS
  Widget _buildDemoControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.brown[700],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF8B4513), width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'DEMO: Select a String',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stringButton('G'),
              _stringButton('D'),
              _stringButton('A'),
              _stringButton('E'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stringButton(String s) {
    return ElevatedButton(
      onPressed: () => _changeString(s),
      style: ElevatedButton.styleFrom(
        backgroundColor: currentSimulatedString == s
            ? Colors.amber
            : Colors.grey[600],
      ),
      child: Text(s),
    );
  }
}

// GAUGE PAINTER (RESPONSIVE)
class GaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.01;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - (size.width * 0.05);

    paint.color = Colors.blue;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi / 3,
      false,
      paint,
    );

    paint.color = Colors.green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi + pi / 3,
      pi / 3,
      false,
      paint,
    );

    paint.color = Colors.red;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi + 2 * pi / 3,
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

    final double fontSize = size.width * 0.05;
    final textStyle = TextStyle(fontSize: fontSize, color: Colors.white);

    TextPainter(
      text: TextSpan(text: 'LOW', style: textStyle),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, Offset(center.dx - (size.width * 0.3), center.dy - (size.height * 0.3)));

    TextPainter(
      text: TextSpan(text: 'HIGH', style: textStyle),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, Offset(center.dx + (size.width * 0.15), center.dy - (size.height * 0.3)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}