package com.example.flutter_testapplication

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.flutter_testapplication.audio.AudioProcessor
import com.example.flutter_testapplication.audio.FFTAudioService

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.flutter_testapplication.tuner/audio"
    private lateinit var audioProcessor: AudioProcessor
    private val PERMISSION_REQUEST = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        audioProcessor = AudioProcessor()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "startListening" -> handleStartListening(result)
                    "stopListening" -> handleStopListening(result)
                    "getPitch" -> {
                        result.success(
                            mapOf(
                                "pitch" to audioProcessor.currentPitch,
                                "amplitude" to audioProcessor.currentAmplitude
                            )
                        )
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "MethodChannel error: ${e.message}", e)
                result.error("ERROR", "Unexpected error: ${e.message}", null)
            }
        }
    }

    private fun handleStartListening(result: MethodChannel.Result) {
        try {
            startForegroundService()
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to start service: ${e.message}", e)
        }

        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.RECORD_AUDIO
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                PERMISSION_REQUEST
            )
            result.error("PERMISSION", "Requesting microphone permission", null)
        } else {
            try {
                audioProcessor.startListening()
                result.success(null)
            } catch (e: Exception) {
                Log.e("MainActivity", "Failed to start AudioProcessor: ${e.message}", e)
                result.error("ERROR", "Could not start listening", null)
            }
        }
    }

    private fun handleStopListening(result: MethodChannel.Result) {
        try {
            stopService(Intent(this, FFTAudioService::class.java))
            audioProcessor.stopListening()
            result.success(null)
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to stop listening: ${e.message}", e)
            result.error("ERROR", "Could not stop listening", null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        try {
            if (requestCode == PERMISSION_REQUEST && grantResults.isNotEmpty()) {
                if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    audioProcessor.startListening()
                } else {
                    Log.e("MainActivity", "Microphone permission denied")
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Permission handling error: ${e.message}", e)
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    private fun startForegroundService() {
        try {
            val serviceIntent = Intent(this, FFTAudioService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to start foreground service: ${e.message}", e)
        }
    }
}
