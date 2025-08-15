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
      // تهيئة القنوات والـlisteners في العزل الخلفي
      await LocalService.initNotifications();

      final prefs = await SharedPreferences.getInstance();
      final alertsEnabled = prefs.getBool('alerts_enabled') ?? true;
      final onlyWhenOpen = prefs.getBool('only_when_open') ?? false;
      final appIsRunning = prefs.getBool('appIsRunning') ?? false;
      final lastActive = prefs.getInt('last_active_ts') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final isReallyRunning = appIsRunning && (now - lastActive) < 10 * 1000;

      if (!alertsEnabled) return Future.value(true);

      if (task == _task) {
        final allow = !onlyWhenOpen || isReallyRunning;

        if (allow) {
          // إشعار ثابت + بدء رنّة مستمرة
          await LocalService.showPersistentAlarm();
          await LocalService.startRingingLoop();
        }

        // إعادة التسجـيل للمرّة الجاية (one-off pattern)
        await Workmanager().registerOneOffTask(
          _unique,
          _task,
          constraints:  Constraints(requiresCharging: true),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
      }
      return Future.value(true);
    } catch (_) {
      return Future.value(false);
    }
  });
}
