package com.example.voltify

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import flutter.overlay.window.flutter_overlay_window.OverlayService

class PowerConnectionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_POWER_CONNECTED) {
            // Show the overlay with custom dimensions
            val serviceIntent = Intent(context, OverlayService::class.java)
            serviceIntent.putExtra("enableDrag", false)
            serviceIntent.putExtra("overlayTitle", "Voltify Alarm")
            serviceIntent.putExtra("overlayContent", "Charging Alarm Active")
            serviceIntent.putExtra("height", 400)
            // Start as foreground service
            context.startForegroundService(serviceIntent)
        } else if (action == Intent.ACTION_POWER_DISCONNECTED) {
            // Hide the overlay
            val stopIntent = Intent(context, OverlayService::class.java)
            context.stopService(stopIntent)
        }
    }
}
