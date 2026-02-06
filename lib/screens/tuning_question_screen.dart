import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'violin_tuner.dart';
import 'knights_practice_timer.dart';
import '../services/storage_service.dart';

class TuningQuestionScreen extends StatefulWidget {
  const TuningQuestionScreen({super.key});

  @override
  State<TuningQuestionScreen> createState() => _TuningQuestionScreenState();
}

class _TuningQuestionScreenState extends State<TuningQuestionScreen> {
  String selectedCharacter = 'knight';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCharacter();
  }

  Future<void> _loadCharacter() async {
    final character = await StorageService.loadSelectedCharacter();
    if (mounted) {
      setState(() {
        selectedCharacter = character;
        isLoading = false;
      });
    }
  }

  Future<void> _requestMicrophoneAndNavigate(BuildContext context) async {
    // Check current permission status
    PermissionStatus status = await Permission.microphone.status;
    
    if (status.isGranted) {
      // Permission already granted, go directly to tuner
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ViolinTuner()),
        );
      }
      return;
    }
    
    // Show a friendly message before requesting
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.blue[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white, width: 3),
          ),
          content: const Text(
            'The tuner needs access to your microphone to hear your violin.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _handleMicrophonePermission(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleMicrophonePermission(BuildContext context) async {
    // Request the permission
    PermissionStatus status = await Permission.microphone.request();
    
    if (!context.mounted) return;
    
    if (status.isGranted) {
      // Permission granted! Go to tuner
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ViolinTuner()),
      );
    } else if (status.isDenied) {
      // Permission denied - show explanation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.orange[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white, width: 3),
          ),
          title: const Text(
            'Microphone Access Needed',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'The violin tuner needs microphone access to detect your violin\'s pitch. Please grant permission to use the tuner.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Try again
                await _handleMicrophonePermission(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied - direct to settings
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.red[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white, width: 3),
          ),
          title: const Text(
            'Permission Required',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Microphone permission is required for the tuner. Please enable it in your device settings.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red[700],
              ),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double w = size.width;
    final double h = size.height;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFDAA520),
        appBar: AppBar(
          title: const Text('Tuning Help'),
          backgroundColor: Colors.red[900],
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFB22222),
          ),
        ),
      );
    }

    // Determine which image to show based on selected character
    String imagePath = selectedCharacter == 'gerbil' 
        ? 'assets/images/Gerbil_tuning.webp'
        : 'assets/images/help_tuning.webp';

    return Scaffold(
      backgroundColor: const Color(0xFFDAA520),
      appBar: AppBar(
        title: const Text('Tuning Help'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(w * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Custom Image/Fallback Section ---
                Container(
                  constraints: BoxConstraints.loose(Size(w * 0.7, h * 0.4)),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        'Do you need help tuning?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: w * 0.07,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB22222),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: h * 0.05),

                // YES button - NOW WITH PERMISSION REQUEST
                SizedBox(
                  width: w * 0.7,
                  child: ElevatedButton(
                    onPressed: () => _requestMicrophoneAndNavigate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF228B22),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: h * 0.025),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 8,
                    ),
                    child: Text(
                      'Yes',
                      style: TextStyle(
                        fontSize: w * 0.07,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.025),

                // NO button - unchanged
                SizedBox(
                  width: w * 0.7,
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
                      backgroundColor: const Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: h * 0.025),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 8,
                    ),
                    child: Text(
                      'No',
                      style: TextStyle(
                        fontSize: w * 0.07,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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