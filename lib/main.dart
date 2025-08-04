import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voltify/background%20service/work_manager.dart';
import 'package:voltify/notification/local_service.dart';
import 'package:voltify/screens/home_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

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


  runApp(Init());
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
