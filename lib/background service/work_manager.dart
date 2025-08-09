import 'dart:developer';
import 'package:workmanager/workmanager.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkManagerHandler {
  static final Workmanager _instance = Workmanager();
  static final Battery _battery = Battery();
  static bool _isAppRunning = false;

  static void setAppRunning(bool isRunning) {
    _isAppRunning = isRunning;
    log("📱 App running status: $_isAppRunning");
  }

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    log("📢 CallbackDispatcher started");

    _instance.executeTask((task, inputData) async {
      log("🚀 Task started: $task");

      try {
        if (task == "check_charging_status") {
          await _checkChargingAndShowOverlay();
        } else {
          log("✅ Doing some background work...");
          await Future.delayed(Duration(seconds: 2));
        }

        log("🏁 Task finished successfully");
        return Future.value(true);
      } catch (e, st) {
        log("❌ Task failed: $e");
        log("StackTrace: $st");
        return Future.value(false);
      }
    });
  }

  static Future<void> _checkChargingAndShowOverlay() async {
    try {
      // Check if app is running from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final appIsRunning = prefs.getBool('appIsRunning') ?? false;

      log("📱 App running status: $appIsRunning");

      if (!appIsRunning) {
        log("📱 App is not running, skipping overlay");
        await FlutterOverlayWindow.closeOverlay();
        return;
      }

      // Check battery charging status
      final batteryStatus = await _battery.batteryState;
      log("🔋 Battery status: $batteryStatus");

      if (batteryStatus == BatteryState.charging ||
          batteryStatus == BatteryState.full) {
        log("⚡ Device is charging, showing overlay");

        // Check if overlay permission is granted
        if (await FlutterOverlayWindow.isPermissionGranted()) {
          // Show the overlay
          await FlutterOverlayWindow.showOverlay(
            enableDrag: true,
            overlayTitle: "Voltify Alarm",
            overlayContent: "Charging Alarm Active",
            flag: OverlayFlag.defaultFlag,
            alignment: OverlayAlignment.center,
            visibility: NotificationVisibility.visibilityPublic,
            positionGravity: PositionGravity.auto,
          );
          log("🎉 Overlay shown successfully from background service");
        } else {
          log("❌ Overlay permission not granted");
        }
      } else {
        log("🔌 Device is not charging, hiding overlay");
        // Hide overlay if it's showing
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (e) {
      log("❌ Error checking charging status: $e");
    }
  }

  static Future<void> init() async {
    log("⚙️ Starting Workmanager initialization");
    await _instance.initialize(callbackDispatcher);
    log("✅ Workmanager initialized successfully");

    // Register charging monitoring task
    await registerChargingMonitor();
  }

  static Future<void> registerChargingMonitor() async {
    log("📝 Registering charging monitor task");

    // Register a more frequent task to check charging status
    await _instance.registerPeriodicTask(
      "check_charging_status",
      "Charging Status Monitor",
      frequency: Duration(
        seconds: 30,
      ), // Check every 30 seconds for better responsiveness
    );

    log("📌 Charging monitor task registered successfully");
  }

  // Method to trigger charging check manually
  static Future<void> triggerChargingCheck() async {
    log("🔌 Manual trigger - checking charging status");
    await _checkChargingAndShowOverlay();
  }

  static Future<void> registerTaskNow({
    required String id,
    required String name,
  }) async {
    log("📝 Registering task: $id - $name");

    await _instance.registerOneOffTask(
      id,
      name,
      initialDelay: Duration(seconds: 1), // هتشتغل بعد ثانية واحدة بس
    );

    log("📌 Task registered successfully");
  }
}
