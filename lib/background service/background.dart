import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voltify/notification/local_service.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final data = await SharedPreferences.getInstance();
    final appIsRunning = data.getBool('appIsRunning') ?? false;
    try {
      debugPrint("app is running: $appIsRunning 🥱");
      if (task == 'Electricity on' && appIsRunning) {
        await Future.delayed(const Duration(seconds: 5));
        await LocalService.showBasicNotification();
        debugPrint("Basic notification shown ⚡");
      }
      return Future.value(true);
    } catch (error) {
      return Future.value(false);
    }
  });
}
