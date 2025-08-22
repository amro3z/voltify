import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voltify/background%20service/work_manager.dart';
import 'package:voltify/notification/local_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:voltify/screens/welcome_screen.dart';
import 'package:voltify/widget/alarm_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voltify/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // متستناش تهيئات تقيلة هنا؛ اعرض UI بسرعة
  runApp(const Init());
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterOverlayWindow.isPermissionGranted().then((granted) {
    if (granted) {
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          home: const AlarmWidget(),
        ),
      );
    } else {
      debugPrint("Overlay permission not granted");
    }
  });
}

class Init extends StatefulWidget {
  const Init({super.key});
  @override
  State<Init> createState() => _InitState();
}

class _InitState extends State<Init> with WidgetsBindingObserver {
  bool _handlingResume = false;
  bool? _seenWelcome; // null = لسه بتحميل

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSeenWelcome();

    // ✨ نفّذ التهيئات التقيلة بعد أول فريم علشان السبلاتش تختفي فورًا
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Future.wait([
          WorkManager.init(),
          LocalService.initNotifications(), // فيها طلب إذن POST_NOTIFICATIONS لو محتاج
        ]);
      } catch (e) {
        debugPrint('Init heavy tasks error: $e');
      }
    });
  }

  Future<void> _loadSeenWelcome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _seenWelcome = prefs.getBool('seen_welcome') ?? false;
      });
    } catch (e) {
      debugPrint('⚠️ load prefs error: $e');
      setState(() => _seenWelcome = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  Future<void> _onAppResumed() async {
    if (_handlingResume) return;
    _handlingResume = true;
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final overlayGranted = await FlutterOverlayWindow.isPermissionGranted();
      final notifGranted = await Permission.notification.status;
      final sysAlertGranted = await Permission.systemAlertWindow.status;
      debugPrint(
        "Overlay:$overlayGranted  Notif:${notifGranted.isGranted}  SysAlert:${sysAlertGranted.isGranted}",
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("⚠️ Error on resume handling: $e");
    } finally {
      _handlingResume = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_seenWelcome == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final Widget start = (_seenWelcome == true)
        ? const HomeScreen()
        : const WelcomeScreen();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: start,
    );
  }
}
