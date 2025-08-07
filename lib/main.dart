import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voltify/background%20service/work_manager.dart';
import 'package:voltify/notification/local_service.dart';
import 'package:voltify/screens/home_screen.dart';
import 'package:voltify/screens/alarm_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';

const platform = MethodChannel('voltify/intent');

Future<void> checkIntentAndOpenAlarm(BuildContext context) async {
  try {
    final shouldOpen = await platform.invokeMethod<bool>('checkIntent');
    if (shouldOpen == true && context.mounted) {
      final data = await SharedPreferences.getInstance();
      final currentTimeZone =
          data.getString('currentTimeZone') ?? 'Africa/Cairo';
      print(
        '🔥 Checking intent: shouldOpenAlarm = $shouldOpen, timezone = $currentTimeZone',
      );
      Navigator.pushNamed(context, '/alarm', arguments: currentTimeZone);
    } else {
      print(
        '🔥 Not navigating: shouldOpenAlarm = $shouldOpen, context.mounted = ${context.mounted}',
      );
    }
  } catch (e) {
    debugPrint("❌ Error checking intent: $e");
  }
}

Future<void> requestSystemAlertWindowPermission() async {
  if (await Permission.systemAlertWindow.isDenied) {
    final status = await Permission.systemAlertWindow.request();
    if (status.isGranted) {
      print('🔥 System Alert Window permission granted');
    } else {
      print('❌ System Alert Window permission denied');
      await openAppSettings();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WorkManager and Notifications
  await Future.wait([
    WorkManagerHandler.init(),
    LocalService.initNotification(),
  ]);

  // Initialize TimeZone
  tz.initializeTimeZones();

  // Request Notification Permission
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // Request SYSTEM_ALERT_WINDOW Permission
  await requestSystemAlertWindowPermission();

  runApp(const Init());
}

class Init extends StatefulWidget {
  const Init({super.key});

  @override
  _InitState createState() => _InitState();
}

class _InitState extends State<Init> {
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    // Set up MethodChannel handler for onNewIntent
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onNewIntent' && _isMounted) {
        final bool shouldOpen = call.arguments as bool;
        print('🔥 Received onNewIntent: shouldOpenAlarm = $shouldOpen');
        if (shouldOpen && mounted) {
          final data = await SharedPreferences.getInstance();
          final currentTimeZone =
              data.getString('currentTimeZone') ?? 'Africa/Cairo';
          print(
            '🔥 Navigating to AlarmScreen from onNewIntent, timezone = $currentTimeZone',
          );
          Navigator.pushNamed(context, '/alarm', arguments: currentTimeZone);
        }
      }
    });

    // Check initial intent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMounted) {
        checkIntentAndOpenAlarm(context);
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voltify',
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/alarm': (context) => AlarmScreen(
          currentTimeZone:
              ModalRoute.of(context)?.settings.arguments as String? ??
              'Africa/Cairo',
        ),
      },
    );
  }
}
