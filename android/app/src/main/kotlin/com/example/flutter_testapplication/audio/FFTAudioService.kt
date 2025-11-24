package com.example.flutter_testapplication.audio

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.example.flutter_testapplication.R

class FFTAudioService : Service() {
    private val channelId = "fft_tuner_channel"
    private lateinit var audioProcessor: AudioProcessor

    override fun onCreate() {
        super.onCreate()
        audioProcessor = AudioProcessor()
        audioProcessor.startListening()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Violin Tuner Active")
            .setContentText("Listening for violin strings")
            .setSmallIcon(R.drawable.ic_tuner_notification)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
        startForeground(1, notification)

        if (intent?.action == STOP_ACTION) stopSelf()
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Violin Tuner", NotificationManager.IMPORTANCE_LOW)
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        audioProcessor.stopListening()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val STOP_ACTION = "com.example.flutter_testapplication.STOP_TUNING"
    }
}
