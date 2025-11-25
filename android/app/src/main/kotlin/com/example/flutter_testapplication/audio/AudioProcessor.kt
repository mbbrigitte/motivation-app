package com.example.flutter_testapplication.audio

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sqrt

class AudioProcessor {

    private var audioRecord: AudioRecord? = null
    private var isListening = false
    private val fftSize = 4096

    @Volatile var currentPitch: Double = 0.0
    @Volatile var currentAmplitude: Double = 0.0

    private val sampleRate = 44100
    private val channelConfig = AudioFormat.CHANNEL_IN_MONO
    private val audioFormat = AudioFormat.ENCODING_PCM_16BIT
    private val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

    fun startListening() {
        if (audioRecord != null || isListening) return

        try {
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                channelConfig,
                audioFormat,
                max(bufferSize, fftSize * 4)
            )

            audioRecord?.startRecording()
            isListening = true

            Thread {
                try {
                    val buffer = ShortArray(fftSize)
                    val fft = FFT(fftSize)

                    while (isListening) {
                        val read = try {
                            audioRecord?.read(buffer, 0, fftSize, AudioRecord.READ_BLOCKING) ?: 0
                        } catch (e: Exception) {
                            Log.e("AudioProcessor", "Error reading audio: ${e.message}", e)
                            0
                        }

                        if (read < fftSize) {
                            Thread.sleep(10)
                            continue
                        }

                        val audioFloats = FloatArray(fftSize) { buffer[it].toFloat() / 32768f }
                        applyHannWindow(audioFloats)

                        val fftData = try {
                            fft.forwardTransform(audioFloats)
                        } catch (e: Exception) {
                            Log.e("AudioProcessor", "FFT transform failed: ${e.message}", e)
                            FloatArray(fftSize) // fallback empty array
                        }

                        try {
                            val (pitch, amplitude) = findDominantFrequency(fftData)
                            currentPitch = pitch
                            currentAmplitude = amplitude.toDouble()
                        } catch (e: Exception) {
                            Log.e("AudioProcessor", "Error finding dominant frequency: ${e.message}", e)
                        }
                    }
                } catch (e: Exception) {
                    Log.e("AudioProcessor", "Error in listening thread: ${e.message}", e)
                }
            }.apply {
                priority = Thread.MAX_PRIORITY
            }.start()
        } catch (e: Exception) {
            Log.e("AudioProcessor", "Failed to start AudioRecord: ${e.message}", e)
        }
    }

    private fun applyHannWindow(signal: FloatArray) {
        for (i in signal.indices) {
            val window = 0.5f * (1 - cos(2 * PI * i / signal.size).toFloat())
            signal[i] *= window
        }
    }

    private fun findDominantFrequency(fftData: FloatArray): Pair<Double, Float> {
        var maxMagnitude = 0f
        var maxIndex = 0

        for (i in 1 until fftData.size / 2) {
            val real = fftData[2 * i]
            val imag = fftData[2 * i + 1]
            val magnitude = sqrt(real * real + imag * imag)
            if (magnitude > maxMagnitude) {
                maxMagnitude = magnitude
                maxIndex = i
            }
        }

        val freqResolution = sampleRate.toDouble() / fftSize
        val frequency = maxIndex * freqResolution

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
                try { stop() } catch (e: Exception) { /* ignore */ }
                try { release() } catch (e: Exception) { /* ignore */ }
            }
            audioRecord = null
        } catch (e: Exception) {
            Log.e("AudioProcessor", "Error stopping AudioRecord: ${e.message}", e)
        }
    }
}
