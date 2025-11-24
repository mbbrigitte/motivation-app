package com.example.flutter_testapplication.audio

import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

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

    fun forwardTransform(audioFloats: FloatArray): FloatArray {
        val data = FloatArray(2 * n)
        audioFloats.forEachIndexed { i, f -> data[2 * i] = f }

        // Bit-reverse ordering
        var j = 0
        for (i in 0 until 2 * n step 2) {
            if (j > i) {
                var temp = data[j]; data[j] = data[i]; data[i] = temp
                temp = data[j + 1]; data[j + 1] = data[i + 1]; data[i + 1] = temp
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

        return data
    }
}
