package com.example.flutter_testapplication.audio

import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

class FFT(private val n: Int) {

    private val cosTable = FloatArray(n / 2)
    private val sinTable = FloatArray(n / 2)

    init {
        for (i in 0 until n / 2) {
            val angle = 2.0 * PI * i / n
            cosTable[i] = cos(angle).toFloat()
            sinTable[i] = sin(angle).toFloat()
        }
    }

    fun forwardTransform(input: FloatArray): FloatArray {
        val data = FloatArray(2 * n)

        // real values in even indices, imag = 0
        for (i in input.indices) {
            data[2 * i] = input[i]
        }

        // Bit-reverse
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

        // FFT butterflies
        var mmax = 2
        while (mmax < 2 * n) {
            val istep = mmax * 2
            for (m in 0 until mmax step 2) {
                val wReal = cosTable[m / 2]
                val wImag = sinTable[m / 2]

                var k = m
                while (k < 2 * n) {
                    val i = k + mmax

                    val tr = wReal * data[i] - wImag * data[i + 1]
                    val ti = wImag * data[i] + wReal * data[i + 1]

                    data[i] = data[k] - tr
                    data[i + 1] = data[k + 1] - ti

                    data[k] += tr
                    data[k + 1] += ti

                    k += istep
                }
            }
            mmax = istep
        }

        return data   // <-- THIS FIXES EVERYTHING
    }
}
