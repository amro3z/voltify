import 'dart:developer';
import 'package:voltify/background%20service/background.dart';
import 'package:workmanager/workmanager.dart';


class WorkManager {
  static final Workmanager _instance = Workmanager();

  static Future<void> init() async {
    try {
      log("Starting Workmanager initialization");
      await _instance.initialize(callbackDispatcher);
      log("Workmanager initialized successfully");
      await registerTask(id: "1", name: "Electricity on");
    } catch (e) {
      log("Error during initialization or task registration: $e");
    }
  }

  static Future<void> registerTask({
    required String id,
    required String name,
  }) async {
    try {
      await Workmanager().registerPeriodicTask(
        id,
        name,
        constraints:  Constraints(
          requiresCharging: true,
        ),
        frequency: Duration(minutes: 15),
      );
      log("Task registered with id: $id and name: $name (charging constraint)");
    } catch (e) {
      log("Error registering task: $e");
    }
  }

  static void cancelTask({required String taskId}) {
    Workmanager().cancelByUniqueName(taskId);
    log("Task cancelled");
  }
}
