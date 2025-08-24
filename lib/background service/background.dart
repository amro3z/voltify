// lib/background_service/background.dart
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voltify/notification/local_service.dart';

const _unique = 'wm_on_charge';
const _task = 'Electricity on';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await LocalService.initNotifications(background: true);

      final prefs = await SharedPreferences.getInstance();
      final alertsEnabled = prefs.getBool('alerts_enabled') ?? true;
      final appIsRunning = prefs.getBool('appIsRunning') ?? false;

      if (!alertsEnabled) return Future.value(true);

      if (task == _task && appIsRunning) {
        print('app is running: ${appIsRunning.toString()}');

        await LocalService.showPersistentAlarm();
        try {
          await LocalService.startRingingLoop();
        } catch (_) {}

        await Workmanager().registerOneOffTask(
          _unique,
          _task,
          constraints: Constraints(requiresCharging: true),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
      }
      return Future.value(true);
    } catch (_) {
      return Future.value(false);
    }
  });
}
