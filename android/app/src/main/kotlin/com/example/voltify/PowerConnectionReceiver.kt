package com.example.voltify

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import flutter.overlay.window.flutter_overlay_window.OverlayService

class PowerConnectionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d("PowerReceiver", "Received action: $action")
        
        // Check if app is enabled via SharedPreferences
        val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val appIsRunning = prefs.getBoolean("flutter.appIsRunning", false)
        
        Log.d("PowerReceiver", "App running status: $appIsRunning")
        
        if (!appIsRunning) {
            Log.d("PowerReceiver", "App is not running, ignoring power event")
            return
        }
        
        if (action == Intent.ACTION_POWER_CONNECTED) {
            Log.d("PowerReceiver", "Power connected - showing overlay")
            // Show the overlay with custom dimensions
            val serviceIntent = Intent(context, OverlayService::class.java)
            serviceIntent.putExtra("enableDrag", true)
            serviceIntent.putExtra("overlayTitle", "Voltify Alarm")
            serviceIntent.putExtra("overlayContent", "Charging Alarm Active")
            serviceIntent.putExtra("height", 400)
            // Start as foreground service
            try {
                context.startForegroundService(serviceIntent)
                Log.d("PowerReceiver", "Overlay service started successfully")
            } catch (e: Exception) {
                Log.e("PowerReceiver", "Error starting overlay service: ${e.message}")
            }
        } else if (action == Intent.ACTION_POWER_DISCONNECTED) {
            Log.d("PowerReceiver", "Power disconnected - hiding overlay")
            // Hide the overlay
            val stopIntent = Intent(context, OverlayService::class.java)
            try {
                context.stopService(stopIntent)
                Log.d("PowerReceiver", "Overlay service stopped successfully")
            } catch (e: Exception) {
                Log.e("PowerReceiver", "Error stopping overlay service: ${e.message}")
            }
        }
    }
}
