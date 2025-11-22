package com.example.flutter_testapplication

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.*
import kotlin.concurrent.thread

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.flutter_testapplication.tuner/audio"
    private lateinit var audioProcessor: AudioProcessor

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        audioProcessor = AudioProcessor()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startListening" -> {
                        audioProcessor.startListening()
                        result.success(null)
                    }
                    "stopListening" -> {
                        audioProcessor.stopListening()
                        result.success(null)
                    }
                    "getPitch" -> {
                        val pitch = audioProcessor.getCurrentPitch()
                        val amplitude = audioProcessor.getAmplitude()
                        result.success(mapOf("pitch" to pitch, "amplitude" to amplitude))
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

class AudioProcessor {
    private var audioRecord: AudioRecord? = null
    private var isListening = false
    private var currentPitch: Double = 0.0
    private var currentAmplitude: Double = 0.0

    private val SAMPLE_RATE = 44100
    private val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
    private val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
    private val BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)

    fun startListening() {
        if (audioRecord != null) return

        audioRecord = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            AudioRecord.Builder()
                .setAudioSource(MediaRecorder.AudioSource.MIC)
                .setAudioFormat(AudioFormat.Builder()
                    .setEncoding(AUDIO_FORMAT)
                    .setSampleRate(SAMPLE_RATE)
                    .setChannelMask(CHANNEL_CONFIG)
                    .build())
                .setBufferSizeInBytes(BUFFER_SIZE)
                .build()
        } else {
            AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                BUFFER_SIZE
            )
        }

        audioRecord?.startRecording()
        isListening = true

        Thread {
            val audioBuffer = ShortArray(BUFFER_SIZE)

            while (isListening) {
                val bytesRead = audioRecord?.read(audioBuffer, 0, BUFFER_SIZE) ?: 0

                if (bytesRead > 0) {
                    // Calculate RMS
                    val rms = sqrt(audioBuffer.take(bytesRead)
                        .map { (it.toDouble() / 32768.0).pow(2.0) }
                        .average())
                    currentAmplitude = rms

                    // Detect pitch
                    val pitch = detectPitch(audioBuffer.take(bytesRead).map { it.toFloat() }.toFloatArray())
                    if (pitch != null) {
                        currentPitch = pitch
                    }
                }
            }
        }.start() // removed daemon=true, use .start() instead
    }

    fun stopListening() {
        isListening = false
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
    }

    fun getCurrentPitch(): Double = currentPitch
    fun getAmplitude(): Double = currentAmplitude

    private fun detectPitch(signal: FloatArray): Double? {
        val autocorr = autocorrelate(signal)

        val minPeriod = (SAMPLE_RATE / 800).toInt()
        val maxPeriod = (SAMPLE_RATE / 150).toInt()

        var maxValue = 0f
        var maxLag = minPeriod

        for (lag in minPeriod until minOf(maxPeriod, autocorr.size)) {
            if (autocorr[lag] > maxValue) {
                maxValue = autocorr[lag]
            }
        }

        for (lag in minPeriod until minOf(maxPeriod, autocorr.size)) {
            if (autocorr[lag] > maxValue * 0.9f) {
                maxLag = lag
                break
            }
        }

        return if (maxValue > 0.01f) SAMPLE_RATE.toDouble() / maxLag else null
    }

    private fun autocorrelate(signal: FloatArray): FloatArray {
        val result = FloatArray(signal.size / 2)

        for (lag in result.indices) {
            var sum = 0f
            for (i in 0 until signal.size - lag) {
                sum += signal[i] * signal[i + lag]
            }
            result[lag] = sum / signal.size
        }

        return result
    }
}
