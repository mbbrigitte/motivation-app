package com.example.flutter_testapplication.audio

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class FFTAudioService : Service() {

    private val channelId = "fft_tuner_channel"
    private var audioProcessor: AudioProcessor? = null

    override fun onCreate() {
        super.onCreate()
        try {
            audioProcessor = AudioProcessor()
            audioProcessor?.startListening()
        } catch (e: Exception) {
            Log.e("FFTAudioService", "Error starting AudioProcessor: ${e.message}", e)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()
        val notification = buildNotification()
        startForeground(1, notification)

        if (intent?.action == STOP_ACTION) {
            stopSelf()
        }

        return START_STICKY
    }

    private fun buildNotification(): Notification {
        return try {
            NotificationCompat.Builder(this, channelId)
                .setContentTitle("Violin Tuner Active")
                .setContentText("Listening for violin strings")
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .build()
        } catch (e: Exception) {
            Log.e("FFTAudioService", "Failed to build notification: ${e.message}", e)
            Notification()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val channel = NotificationChannel(
                    channelId,
                    "Violin Tuner",
                    NotificationManager.IMPORTANCE_LOW
                )
                val manager = getSystemService(NotificationManager::class.java)
                manager?.createNotificationChannel(channel)
            } catch (e: Exception) {
                Log.e("FFTAudioService", "Failed to create notification channel: ${e.message}", e)
            }
        }
    }

    override fun onDestroy() {
        try {
            audioProcessor?.stopListening()
        } catch (e: Exception) {
            Log.e("FFTAudioService", "Error stopping AudioProcessor: ${e.message}", e)
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val STOP_ACTION = "com.example.flutter_testapplication.STOP_TUNING"
    }
}
