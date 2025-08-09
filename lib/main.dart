import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voltify/background%20service/work_manager.dart';
import 'package:voltify/notification/local_service.dart';
import 'package:voltify/screens/home_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:voltify/widget/alarm_widget.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Future.wait([WorkManagerHandler.init(), LocalService.initNotification()]);
  tz.initializeTimeZones();
  // طلب الأذونات
  if (await FlutterOverlayWindow.isPermissionGranted() == false) {
    await FlutterOverlayWindow.requestPermission();
  }
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // تأخير صغير للتأكد من التهيئة
  await Future.delayed(const Duration(milliseconds: 500));

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

class Init extends StatefulWidget {
  const Init({super.key});

  @override
  State<Init> createState() => _InitState();
}

class _InitState extends State<Init> with WidgetsBindingObserver {
  final Battery _battery = Battery();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Set app as running initially
    WorkManagerHandler.setAppRunning(true);

    // Check initial battery state and trigger work manager
    final initialBatteryState = await _battery.batteryState;
    print("🔋 Initial battery state: $initialBatteryState");

    // Trigger work manager to check charging status immediately
    await WorkManagerHandler.triggerChargingCheck();
  }

  // Remove these methods as we'll use work manager instead

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        WorkManagerHandler.setAppRunning(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        WorkManagerHandler.setAppRunning(false);
        break;
      case AppLifecycleState.inactive:
        // Keep app running status as is
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voltify',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}
