import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voltify/background%20service/work_manager.dart';
import 'package:voltify/notification/local_service.dart';
import 'package:voltify/screens/home_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:voltify/widget/alarm_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize WorkManager and LocalService before running the app
  await Future.wait([
    WorkManager.init(),
    LocalService.initNotifications(),
  ]);
  tz.initializeTimeZones();
  if (await FlutterOverlayWindow.isPermissionGranted() == false) {
    await FlutterOverlayWindow.requestPermission();
  }
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  runApp(const Init());
}

@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: AlarmWidget(),
    ),
  );
}

class Init extends StatelessWidget {
  const Init({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}
