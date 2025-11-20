import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

class ViolinTuner extends StatefulWidget {
  const ViolinTuner({super.key});

  @override
  State<ViolinTuner> createState() => _ViolinTunerState();
}

class _ViolinTunerState extends State<ViolinTuner> with TickerProviderStateMixin {
  static const platform = MethodChannel('com.flutter_testapplication.tuner/audio');
  
  // Violin strings: G3, D4, A4, E5
  static const Map<String, double> violinStrings = {
    'G': 196.00,
    'D': 293.66,
    'A': 440.00,
    'E': 659.26,
  };
  
  double currentPitch = 0.0;
  double currentAmplitude = 0.0;
  String currentString = '';
  double detuneAmount = 0.0; // cents from target (-50 to +50)
  bool isInTune = false;
  bool isTooHigh = false;
  bool isTooLow = false;
  
  List<double> pitchBuffer = [];
  Timer? pitchTimer;
  late AnimationController needleController;
  late AnimationController monsterController;
  
  @override
  void initState() {
    super.initState();
    needleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    monsterController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _requestPermissionsAndStart();
  }
  
  Future<void> _requestPermissionsAndStart() async {
    try {
      await platform.invokeMethod('startListening');
      _startPitchDetection();
    } catch (e) {
      print('Error: $e');
    }
  }
  
  void _startPitchDetection() {
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
    
    // Find nearest string
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
    
    // Only switch strings if signal is stable and change is significant
    if (nearestString != currentString) {
      // Check if change is larger than half distance between strings
      double halfDistanceToNext = _getHalfDistanceToNextString(nearestString);
      if (minDistance > halfDistanceToNext && pitchBuffer.length < 3) {
        return; // Still transitioning
      }
    }
    
    currentString = nearestString;
    
    // Calculate detune in cents (100 cents = 1 semitone)
    detuneAmount = 1200 * log(currentPitch / targetFreq) / log(2);
    
    // Clamp to reasonable range
    detuneAmount = detuneAmount.clamp(-50.0, 50.0);
    
    // Check if in tune (within 5 cents)
    isInTune = detuneAmount.abs() < 5;
    isTooHigh = detuneAmount > 5;
    isTooLow = detuneAmount < -5;
    
    needleController.animateTo(
      (detuneAmount + 50) / 100, // Normalize to 0-1 range
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
  
  @override
  void dispose() {
    pitchTimer?.cancel();
    needleController.dispose();
    monsterController.dispose();
    platform.invokeMethod('stopListening');
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Current String Display
                Text(
                  currentString.isNotEmpty ? 'String: $currentString' : 'Waiting...',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB22222),
                    fontFamily: 'Georgia',
                  ),
                ),
                
                const SizedBox(height: 10),
                
                Text(
                  currentPitch > 0 ? '${currentPitch.toStringAsFixed(1)} Hz' : '-- Hz',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF8B0000),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Needle Gauge
                _buildNeedleGauge(),
                
                const SizedBox(height: 50),
                
                // Monster Feedback
                _buildMonster(),
                
                const SizedBox(height: 40),
                
                // Tuning Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getTuningStatusColor(),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFF8B4513),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _getTuningStatusText(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNeedleGauge() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Gauge background
        Container(
          width: 300,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.brown[800],
            borderRadius: BorderRadius.circular(150),
            border: Border.all(
              color: const Color(0xFF8B4513),
              width: 4,
            ),
          ),
          child: CustomPaint(
            painter: GaugePainter(),
          ),
        ),
        
        // Needle
        Transform.rotate(
          angle: (needleController.value - 0.5) * pi,
          child: Container(
            width: 4,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        
        // Center circle
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF8B4513), width: 2),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMonster() {
    return Column(
      children: [
        // Monster eyes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEye(),
            const SizedBox(width: 60),
            _buildEye(),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Monster mouth
        if (isInTune)
          const Text('😊', style: TextStyle(fontSize: 80))
        else if (isTooHigh)
          const Text('😠', style: TextStyle(fontSize: 80))
        else if (isTooLow)
          const Text('😢', style: TextStyle(fontSize: 80))
        else
          const Text('😐', style: TextStyle(fontSize: 80)),
      ],
    );
  }
  
  Widget _buildEye() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _getEyeColor(),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
      ),
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
  
  Color _getEyeColor() {
    if (isInTune) return Colors.green;
    if (isTooHigh) return Colors.red;
    if (isTooLow) return Colors.blue;
    return Colors.grey;
  }
  
  Color _getTuningStatusColor() {
    if (isInTune) return const Color(0xFF228B22);
    if (isTooHigh) return const Color(0xFFCC0000);
    if (isTooLow) return const Color(0xFF0066CC);
    return Colors.grey[700]!;
  }
  
  String _getTuningStatusText() {
    if (currentAmplitude < 0.005) return 'Play the string...';
    if (currentString.isEmpty) return 'Out of range';
    if (isInTune) return '✓ In Tune!';
    if (isTooHigh) return '↓ Too High (${detuneAmount.toStringAsFixed(1)} cents)';
    if (isTooLow) return '↑ Too Low (${detuneAmount.toStringAsFixed(1)} cents)';
    return '';
  }
}

class GaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    
    // Draw gauge arc
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
    
    // Draw labels
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'LOW',
        style: TextStyle(color: Colors.blue, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - 50, center.dy + 70));
    
    final textPainter2 = TextPainter(
      text: const TextSpan(
        text: 'HIGH',
        style: TextStyle(color: Colors.red, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter2.layout();
    textPainter2.paint(canvas, Offset(center.dx + 40, center.dy + 70));
  }
  
  @override
  bool shouldRepaint(GaugePainter oldDelegate) => true;
}