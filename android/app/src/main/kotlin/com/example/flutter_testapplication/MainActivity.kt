package com.violinadventure.vma

import android.Manifest
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.violinadventure.vma.audio.AudioProcessor

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.flutter_testapplication.tuner/audio"
    private lateinit var audioProcessor: AudioProcessor
    private val PERMISSION_REQUEST = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        audioProcessor = AudioProcessor()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "startListening" -> handleStartListening(result)
                        "stopListening" -> {
                            audioProcessor.stopListening()
                            result.success(null)
                        }
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
                    result.error("ERROR", e.message, null)
                }
            }
    }

    private fun handleStartListening(result: MethodChannel.Result) {
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
                Log.e("MainActivity", "Failed to start: ${e.message}", e)
                result.error("ERROR", "Could not start listening", null)
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST && grantResults.isNotEmpty()) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                audioProcessor.startListening()
            } else {
                Log.e("MainActivity", "Microphone permission denied")
            }
        }
    }
}