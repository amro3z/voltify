import 'dart:developer';
import 'package:workmanager/workmanager.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkManagerHandler {
  static final Workmanager _instance = Workmanager();
  static final Battery _battery = Battery();
  static bool _isAppRunning = false;
  static bool _isOverlayShowing = false; // Track overlay state
  static BatteryState? _previousBatteryState; // Track previous battery state

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

      // Check battery charging status
      final batteryStatus = await _battery.batteryState;
      log("🔋 Battery status: $batteryStatus");

      final isCharging =
          batteryStatus == BatteryState.charging ||
          batteryStatus == BatteryState.full;

      if (!appIsRunning || !isCharging) {
        // Hide overlay if app not running or not charging
        if (_isOverlayShowing) {
          try {
            await FlutterOverlayWindow.closeOverlay();
            _isOverlayShowing = false;
            log("✅ Overlay closed (not charging or app not running)");
          } catch (e) {
            log("❌ Error closing overlay: $e");
            _isOverlayShowing = false;
          }
        }
        return;
      }

      // If charging and app is running, ensure overlay is showing
      if (!_isOverlayShowing) {
        if (await FlutterOverlayWindow.isPermissionGranted()) {
          try {
            await FlutterOverlayWindow.showOverlay(
              // Specify fixed overlay height
              height: 400,
              enableDrag: false,
              overlayTitle: "Voltify Alarm",
              overlayContent:
                  "Charging Alarm Active", // Use your custom overlay entrypoint
            );
            _isOverlayShowing = true;
            log("🎉 Overlay shown successfully (charging and app running)");
          } catch (e) {
            log("❌ Error showing overlay: $e");
            _isOverlayShowing = false;
          }
        } else {
          log("❌ Overlay permission not granted");
        }
      } else {
        log("📱 Overlay already showing (charging and app running)");
      }
    } catch (e) {
      log("❌ Error checking charging status: $e");
      _isOverlayShowing = false;
    }
  }

  static Future<void> init() async {
    log("⚙️ Starting Workmanager initialization");
    // Initialize WorkManager; enable debug mode for testing
    await _instance.initialize(callbackDispatcher, isInDebugMode: true);
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
        seconds: 15, // Check more frequently for better responsiveness
      ),
    );

    log("📌 Charging monitor task registered successfully");
  }

  // Method to trigger charging check manually
  static Future<void> triggerChargingCheck() async {
    log("🔌 Manual trigger - checking charging status");
    await _checkChargingAndShowOverlay();
  }

  // Method to manually close overlay
  static Future<void> closeOverlay() async {
    if (_isOverlayShowing) {
      try {
        await FlutterOverlayWindow.closeOverlay();
        _isOverlayShowing = false;
        log("✅ Overlay closed manually");
      } catch (e) {
        log("❌ Error closing overlay manually: $e");
        _isOverlayShowing = false;
      }
    }
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
