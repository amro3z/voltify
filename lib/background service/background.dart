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
      // الاحتفاظ بالحاجات دي لو عايز تستخدمها لاحقًا
      // final onlyWhenOpen = prefs.getBool('only_when_open') ?? false;
      // final appIsRunning = prefs.getBool('appIsRunning') ?? false;
      // final lastActive = prefs.getInt('last_active_ts') ?? 0;

      if (!alertsEnabled) return Future.value(true);

      if (task == _task) {
        // 1) إشعار القناة (يعرض/يهتز/قد يرن حسب إعدادات الروم)
        await LocalService.showPersistentAlarm();

        // 2) الصوت الحقيقي عبر FGS + just_audio (Alarm usage)
        //    نشغّله دايمًا حتى لو التطبيق Terminated
        try {
          await LocalService.startRingingLoop();
        } catch (_) {
          // fallback: تجاهل أي خطأ بدون كراش
        }

        // إعادة التسجيـل للمرّة الجاية (one-off pattern)
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
