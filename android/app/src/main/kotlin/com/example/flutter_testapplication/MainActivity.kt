package com.example.flutter_testapplication

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.flutter_testapplication.audio.AudioProcessor

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.flutter_testapplication.tuner/audio"
    private lateinit var audioProcessor: AudioProcessor
    private val PERMISSION_REQUEST = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        audioProcessor = AudioProcessor()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> handleStartListening(result)
                "stopListening" -> handleStopListening(result)
                "getPitch" -> result.success(
                    mapOf(
                        "pitch" to audioProcessor.currentPitch,
                        "amplitude" to audioProcessor.currentAmplitude
                    )
                )
                else -> result.notImplemented()
            }
        }
    }

    private fun handleStartListening(result: MethodChannel.Result) {
        // Check/request permissions
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                PERMISSION_REQUEST
            )
            result.error("PERMISSION", "Requesting permissions", null)
        } else {
            try {
                audioProcessor.startListening()
                result.success(null)
            } catch (e: SecurityException) {
                result.error("PERMISSION", "Microphone access denied", null)
            }
        }
    }

    private fun handleStopListening(result: MethodChannel.Result) {
        audioProcessor.stopListening()
        result.success(null)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode == PERMISSION_REQUEST && grantResults.isNotEmpty()) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                audioProcessor.startListening()
            }
        }
    }
}
