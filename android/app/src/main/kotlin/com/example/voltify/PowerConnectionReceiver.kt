package com.example.voltify

// Simplified receiver: only handles overlay start/stop. Notification handled in WorkManager.
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import flutter.overlay.window.flutter_overlay_window.OverlayService

class PowerConnectionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d("PowerReceiver", "Received action: $action")

        if (action == Intent.ACTION_POWER_CONNECTED) {
            try {
                val serviceIntent = Intent(context, OverlayService::class.java).apply {
                    putExtra("enableDrag", true)
                    putExtra("overlayTitle", "Voltify Alarm")
                    putExtra("overlayContent", "Charging Alarm Active")
                    putExtra("height", 400)
                }
                context.startForegroundService(serviceIntent)
                Log.d("PowerReceiver", "Overlay service started")
            } catch (e: Exception) {
                Log.e("PowerReceiver", "Overlay start err: ${e.message}")
            }
        } else if (action == Intent.ACTION_POWER_DISCONNECTED) {
            // أوقف الـOverlay فقط (مافيش إشعار هنا)
            try {
                val stopIntent = Intent(context, OverlayService::class.java)
                context.stopService(stopIntent)
                Log.d("PowerReceiver", "Overlay service stopped")
            } catch (e: Exception) {
                Log.e("PowerReceiver", "Overlay stop err: ${e.message}")
            }
        }
    }
}
