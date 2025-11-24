// android/app/src/main/java/com/example/flutter_testapplication/MainActivity.kt
package com.example.flutter_testapplication

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sqrt

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
                "getPitch" -> result.success(mapOf(
                    "pitch" to audioProcessor.currentPitch,
                    "amplitude" to audioProcessor.currentAmplitude
                ))
                else -> result.notImplemented()
            }
        }
    }

    private fun handleStartListening(result: MethodChannel.Result) {
        // Start foreground service FIRST
        startForegroundService()
        
        // Then check/request permissions
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
        stopService(Intent(this, FFTAudioService::class.java))
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

    private fun startForegroundService() {
        val serviceIntent = Intent(this, FFTAudioService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }
}

class AudioProcessor {
    private var audioRecord: AudioRecord? = null
    private var isListening = false
    private val fftSize = 4096  // Higher resolution for accuracy

    // Thread-safe access
    @Volatile var currentPitch: Double = 0.0
    @Volatile var currentAmplitude: Double = 0.0

    private val sampleRate = 44100
    private val channelConfig = AudioFormat.CHANNEL_IN_MONO
    private val audioFormat = AudioFormat.ENCODING_PCM_16BIT
    private val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

    fun startListening() {
        if (audioRecord != null || isListening) return

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            channelConfig,
            audioFormat,
            max(bufferSize, fftSize * 4)  // Ensure buffer fits FFT size
        )

        audioRecord?.startRecording()
        isListening = true

        Thread {
            val buffer = ShortArray(fftSize)
            val fft = FFT(fftSize)

            while (isListening) {
                val read = try {
                    audioRecord?.read(buffer, 0, fftSize, AudioRecord.READ_BLOCKING) ?: 0
                    } catch (e: IllegalStateException) {
                        -1
                    }
            if (read < fftSize) {
                Thread.sleep(10)
                continue
            }

                val audioFloats = FloatArray(fftSize) { buffer[it].toFloat() / 32768f }
                
                // Apply Hann window
                applyHannWindow(audioFloats)

                // Perform FFT (in-place)
                fft.forwardTransform(audioFloats)

                // Find peak frequency
                val (pitch, amplitude) = findDominantFrequency(audioFloats)
                
                currentAmplitude = amplitude.toDouble()
                currentPitch = pitch
            }
    }.apply {
        priority = Thread.MAX_PRIORITY  // Set high priority
    }.start()    }

    private fun applyHannWindow(signal: FloatArray) {
        for (i in signal.indices) {
            val window = 0.5f * (1 - cos(2 * PI * i / signal.size).toFloat())
            signal[i] *= window
        }
    }

    private fun findDominantFrequency(fftData: FloatArray): Pair<Double, Float> {
        var maxMagnitude = 0f
        var maxIndex = 0

        // Look only at first half of FFT bins (Nyquist limit)
        for (i in 1 until fftData.size / 2) {
            val real = fftData[2 * i]
            val imag = fftData[2 * i + 1]
            val magnitude = sqrt(real * real + imag * imag)

            if (magnitude > maxMagnitude) {
                maxMagnitude = magnitude
                maxIndex = i
            }
        }

        // Convert bin index to frequency with fractional precision
        val freqResolution = sampleRate.toDouble() / fftSize
        val frequency = maxIndex * freqResolution

        // Peak interpolation for higher accuracy
        val alpha = fftData[2 * maxIndex]
        val beta = fftData[2 * (maxIndex - 1)]
        val gamma = fftData[2 * (maxIndex + 1)]
        val delta = 0.5 * (gamma - beta) / (2 * alpha - beta - gamma)
        
        return (frequency + delta * freqResolution) to maxMagnitude
    }

    fun stopListening() {
    try {
        isListening = false
        audioRecord?.run {
            try {
                stop()
            } catch (e: IllegalStateException) {
                // Ignore "already stopped" exception
            }
            release()
        }
        audioRecord = null
    } catch (e: Exception) {
        android.util.Log.e("AudioProcessor", "Stop error: ${e.message}")
    }
}
}

// Fast Fourier Transform implementation
class FFT(private val n: Int) {
    private val cos = FloatArray(n / 2)
    private val sin = FloatArray(n / 2)

    init {
        for (i in 0 until n / 2) {
            val angle = 2 * PI * i / n
            cos[i] = cos(angle).toFloat()
            sin[i] = sin(angle).toFloat()
        }
    }

    fun forwardTransform(audioFloats: FloatArray) {
        val data = FloatArray(2 * n)
        audioFloats.forEachIndexed { i, f -> data[2 * i] = f }

        // Bit-reverse ordering
        var j = 0
        for (i in 0 until 2 * n step 2) {
            if (j > i) {
                var temp = data[j]
                data[j] = data[i]
                data[i] = temp

                temp = data[j + 1]
                data[j + 1] = data[i + 1]
                data[i + 1] = temp
            }

            var m = n
            while (j and (m - 1) != 0) m = m shr 1
            j = j xor (m - 1)
        }

        // Butterfly operations
        var mmax = 2
        while (mmax < 2 * n) {
            val istep = mmax * 2
            for (m in 0 until mmax step 2) {
                j = m
                while (j < 2 * n) {
                    val i = j + mmax
                    val tr = cos[m / 2] * data[i] - sin[m / 2] * data[i + 1]
                    val ti = sin[m / 2] * data[i] + cos[m / 2] * data[i + 1]

                    data[i] = data[j] - tr
                    data[i + 1] = data[j + 1] - ti
                    data[j] += tr
                    data[j + 1] += ti

                    j += istep
                }
            }
            mmax = istep
        }

        // Copy back to audioFloats (interleaved)
        audioFloats.forEachIndexed { i, _ ->
            audioFloats[i] = data[i]
        }
    }
}