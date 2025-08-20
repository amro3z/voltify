// lib/background_service/work_manager.dart
import 'dart:developer';
import 'package:voltify/background%20service/background.dart';
import 'package:workmanager/workmanager.dart';

class WorkManager {
  static final Workmanager _instance = Workmanager();

  static Future<void> init() async {
    try {
      print("Starting Workmanager initialization =====");
      await _instance.initialize(callbackDispatcher, isInDebugMode: true);
      log("Workmanager initialized successfully");

      await registerTask(id: "wm_on_charge", name: "Electricity on");
    } catch (e) {
      log("Error during initialization or task registration: $e");
    }
  }

  static Future<void> registerTask({
    required String id,
    required String name,
  }) async {
    try {
      await Workmanager().registerOneOffTask(
        id,
        name,
        constraints: Constraints(requiresCharging: true),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      log("Task registered with id: $id and name: $name (requiresCharging)");
    } catch (e) {
      log("Error registering task: $e");
    }
  }

  static Future<void> cancelTask({required String uniqueName}) async {
    await Workmanager().cancelByUniqueName(uniqueName);
    log("Task cancelled: $uniqueName");
  }
}
