import 'dart:developer';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voltify/notification/local_service.dart';
import 'package:workmanager/workmanager.dart';

class WorkManagerHandler {
  static final Workmanager WorkManager = Workmanager();

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    WorkManager.executeTask((task, inputData) async {
      final data = await SharedPreferences.getInstance();
      final isRunning = data.getBool('appIsRunning') ?? false;

      if (!isRunning) {
        log("Voltify is OFF → cancelling background task");
        await WorkManager.cancelAll();
        return Future.value(false);
      }

      final Battery battery = Battery();
      final BatteryState state = await battery.batteryState;

      if (state == BatteryState.charging) {
        log(
          "Charging detected (while app is closed) — background context only",
        );
        LocalService.showRepeatedNotification();
        return Future.value(true);
      }
      return Future.value(false);
    });
  }

  static Future<void> init() async {
    try {
      log("Starting Workmanager initialization");
      await WorkManager.initialize(callbackDispatcher);
      log("Workmanager initialized successfully");
      await registerTask(id: "1", name: "Enabled Voltify");
    } catch (e) {
      log("Error during initialization or task registration: $e");
    }
  }

  static Future<void> registerTask({
    required String id,
    required String name,
  }) async {
    try {
      await WorkManager.registerOneOffTask(id, name);
      log("Task registered with id: $id and name: $name");
    } catch (e) {
      log("Error registering task: $e");
    }
  }

  static void cancelTask({required String taskId}) {
    WorkManager.cancelByUniqueName(taskId);
    log("Task cancelled: $taskId");
  }

  static Future<void> cancelAllTasks() async {
    await WorkManager.cancelAll();
    log("All background tasks cancelled.");
  }
}
