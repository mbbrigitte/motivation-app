package com.example.flutter_testapplication.audio

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import kotlin.math.*

class AudioProcessor {

    private var audioRecord: AudioRecord? = null
    private var isListening = false
    private var processingThread: Thread? = null

    @Volatile var currentPitch: Double = 0.0
    @Volatile var currentAmplitude: Double = 0.0

    private val SAMPLE_RATE = 44100
    private val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
    private val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
    private val BUFFER_SIZE = 4096
    private val MIN_BUFFER = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)

    fun startListening() {
        if (audioRecord != null || isListening) {
            Log.w("AudioProcessor", "Already listening")
            return
        }

        try {
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                max(MIN_BUFFER, BUFFER_SIZE * 2)
            )

            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                Log.e("AudioProcessor", "AudioRecord not initialized")
                audioRecord = null
                return
            }

            audioRecord?.startRecording()
            isListening = true
            Log.d("AudioProcessor", "✅ AudioRecord started successfully")

            processingThread = Thread {
                val buffer = ShortArray(BUFFER_SIZE)
                val windowBuffer = FloatArray(BUFFER_SIZE)
                var writeIndex = 0

                while (isListening) {
                    try {
                        val read = audioRecord?.read(buffer, 0, BUFFER_SIZE) ?: 0

                        if (read > 0) {
                            // Fill sliding window
                            for (i in 0 until read) {
                                windowBuffer[writeIndex] = buffer[i].toFloat() / 32768.0f
                                writeIndex = (writeIndex + 1) % BUFFER_SIZE
                            }

                            // Calculate RMS amplitude
                            currentAmplitude = calculateRMS(windowBuffer)

                            // Only detect pitch if there's significant sound
                            if (currentAmplitude > 0.01) {
                                val pitch = detectPitchYIN(windowBuffer)
                                if (pitch != null && pitch > 100 && pitch < 1000) {
                                    currentPitch = pitch
                                    Log.d("AudioProcessor", "Detected pitch: $pitch Hz, amplitude: $currentAmplitude")
                                }
                            }
                        } else {
                            Thread.sleep(10)
                        }
                    } catch (e: Exception) {
                        Log.e("AudioProcessor", "Error in processing loop: ${e.message}", e)
                    }
                }
            }
            processingThread?.priority = Thread.MAX_PRIORITY
            processingThread?.start()

        } catch (e: Exception) {
            Log.e("AudioProcessor", "Failed to start AudioRecord: ${e.message}", e)
            audioRecord = null
        }
    }

    fun stopListening() {
        isListening = false
        processingThread?.join(1000)
        try {
            audioRecord?.stop()
            audioRecord?.release()
        } catch (e: Exception) {
            Log.e("AudioProcessor", "Error stopping: ${e.message}", e)
        }
        audioRecord = null
        Log.d("AudioProcessor", "AudioRecord stopped")
    }

    private fun calculateRMS(signal: FloatArray): Double {
        var sum = 0.0
        for (sample in signal) {
            sum += sample * sample
        }
        return sqrt(sum / signal.size)
    }

    private fun detectPitchYIN(signal: FloatArray): Double? {
        val halfSize = signal.size / 2
        val yinBuffer = FloatArray(halfSize)

        // Step 1: Difference function
        yinBuffer[0] = 1f
        for (tau in 1 until halfSize) {
            var delta = 0f
            for (i in 0 until halfSize) {
                val diff = signal[i] - signal[i + tau]
                delta += diff * diff
            }
            yinBuffer[tau] = delta
        }

        // Step 2: Cumulative mean normalized difference
        var cumulativeSum = 0f
        for (tau in 1 until halfSize) {
            cumulativeSum += yinBuffer[tau]
            if (cumulativeSum != 0f) {
                yinBuffer[tau] *= tau / cumulativeSum
            } else {
                yinBuffer[tau] = 1f
            }
        }

        // Step 3: Find minimum below threshold
        val threshold = 0.15f
        var minTau = -1

        for (tau in 2 until halfSize) {
            if (yinBuffer[tau] < threshold) {
                while (tau + 1 < halfSize && yinBuffer[tau + 1] < yinBuffer[tau]) {
                    tau++
                }
                minTau = tau
                break
            }
        }

        // Fallback: find global minimum
        if (minTau == -1) {
            var minValue = Float.MAX_VALUE
            for (tau in 20 until halfSize) {
                if (yinBuffer[tau] < minValue) {
                    minValue = yinBuffer[tau]
                    minTau = tau
                }
            }
        }

        return if (minTau > 0 && minTau < halfSize - 1) {
            val betterTau = parabolicInterpolation(yinBuffer, minTau)
            SAMPLE_RATE.toDouble() / (minTau + betterTau)
        } else {
            null
        }
    }

    private fun parabolicInterpolation(array: FloatArray, index: Int): Double {
        if (index <= 0 || index >= array.size - 1) return 0.0

        val s0 = array[index - 1].toDouble()
        val s1 = array[index].toDouble()
        val s2 = array[index + 1].toDouble()

        return 0.5 * (s0 - s2) / (s0 - 2.0 * s1 + s2)
    }
}