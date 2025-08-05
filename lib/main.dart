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
    if (shouldOpen == true) {
      final data = await SharedPreferences.getInstance();
      final currentTimeZone = data.getString('currentTimeZone') ?? 'Africa/Cairo';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlarmScreen(currentTimeZone: currentTimeZone),
        ),
      );
    }
  } catch (e) {
    debugPrint("Error checking intent: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    WorkManagerHandler.init(),
    LocalService.initNotification(),
  ]);

  tz.initializeTimeZones();

  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  runApp(const Init());
}

class Init extends StatelessWidget {
  const Init({super.key});

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
