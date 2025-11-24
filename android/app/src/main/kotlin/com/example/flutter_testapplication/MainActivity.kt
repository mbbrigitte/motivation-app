package com.example.flutter_testapplication

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.flutter_testapplication.audio.AudioProcessor
import com.example.flutter_testapplication.audio.FFTAudioService

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.flutter_testapplication.tuner/audio"
    private lateinit var audioProcessor: AudioProcessor
    private val PERMISSION_REQUEST_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        audioProcessor = AudioProcessor()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> startListening(result)
                "stopListening" -> stopListening(result)
                "getPitch" -> result.success(mapOf(
                    "pitch" to audioProcessor.currentPitch,
                    "amplitude" to audioProcessor.currentAmplitude
                ))
                else -> result.notImplemented()
            }
        }
    }

    private fun startListening(result: MethodChannel.Result) {
        // Start foreground service first
        startForegroundService()

        // Check microphone permission
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                PERMISSION_REQUEST_CODE
            )
            result.error("PERMISSION", "Requesting microphone permission", null)
        } else {
            try {
                audioProcessor.startListening()
                result.success(null)
            } catch (e: SecurityException) {
                result.error("PERMISSION", "Microphone access denied", null)
            }
        }
    }

    private fun stopListening(result: MethodChannel.Result) {
        audioProcessor.stopListening()
        stopService(Intent(this, FFTAudioService::class.java))
        result.success(null)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            audioProcessor.startListening()
        }
    }

    private fun startForegroundService() {
        val serviceIntent = Intent(this, FFTAudioService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }
}
