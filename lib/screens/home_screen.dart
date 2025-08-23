import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voltify/background service/work_manager.dart';
import 'package:voltify/notification/local_service.dart';
import 'package:voltify/widget/home_body.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final Battery _battery = Battery();
  late SharedPreferences data;

  bool _isInBatterySaveMode = false;
  int _batteryLevel = 0;
  bool appIsRunning = false;
  bool _prefsReady = false;
  bool _isInitializing = false;
  BatteryState _batteryState = BatteryState.unknown;
  late StreamSubscription<BatteryState> _batteryStateSubscription;
  Timer? _batteryInfoTimer;
  late String currentTimeZone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // يبدأ الفلو
    requestPermissions();

    // تهيئة الخدمات + البيانات
    Future.wait([
      WorkManager.init(),
      LocalService.initNotifications(),
      _initialize(),
    ]);
  }

  Future<void> _initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      data = await SharedPreferences.getInstance();
      setState(() {
        appIsRunning = data.getBool('appIsRunning') ?? false;
        _prefsReady = true;
      });

      final String timezone = await FlutterTimezone.getLocalTimezone();
      if (!mounted) return;
      setState(() {
        currentTimeZone = timezone;
        data.setString('currentTimeZone', timezone);
      });

      await _updateBatteryInfo();

      _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
        _updateBatteryState,
      );

      _batteryInfoTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        if (!mounted || !_prefsReady) return;
        await _updateBatteryInfo();
      });
    } catch (e) {
      debugPrint("⚠️ Error initializing: $e");
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _updateBatteryInfo() async {
    try {
      final level = await _battery.batteryLevel;
      final mode = await _battery.isInBatterySaveMode;
      final state = await _battery.batteryState;
      if (mounted) {
        setState(() {
          _batteryLevel = level;
          _isInBatterySaveMode = mode;
          _batteryState = state;
          if (_prefsReady) {
            data.setString('batteryState', state.toString());
          }
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error updating battery info: $e");
    }
  }

  Future<void> requestPermissions() async {
    try {
      final hasOverlay = await FlutterOverlayWindow.isPermissionGranted();
      if (!hasOverlay) {
        await FlutterOverlayWindow.requestPermission();
        return; // هنكمّل بعد الرجوع
      }

      final notif = await Permission.notification.status;
      if (notif.isDenied || notif.isRestricted) {
        await Permission.notification.request();
      }

      final sys = await Permission.systemAlertWindow.status;
      if (sys.isDenied || sys.isRestricted) {
        await Permission.systemAlertWindow.request();
        return; // هنكمّل بعد الرجوع
      }

      await LocalService.requestDndAccessIfNeeded();
    } catch (e) {
      debugPrint("perm error: $e");
    }
  }

  void _updateBatteryState(BatteryState state) {
    if (_batteryState == state || !_prefsReady) return;
    setState(() {
      _batteryState = state;
      data.setString('batteryState', state.toString());
    });
  }

  Future<void> _toggleAppRunning() async {
    if (!_prefsReady) return;
    final newVal = !appIsRunning;
    setState(() {
      appIsRunning = newVal;
    });
    await data.setBool('appIsRunning', newVal);
    if (newVal) {
      await data.setInt(
        'last_active_ts',
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _batteryStateSubscription.cancel();
    _batteryInfoTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _initialize();
      requestPermissions(); // كمّل فلو الصلاحيات بعد الرجوع من Settings
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeBody(
        prefsReady: _prefsReady,
        batteryLevel: _batteryLevel,
        batteryState: _batteryState,
        isInBatterySaveMode: _isInBatterySaveMode,
        appIsRunning: appIsRunning,
        onToggleAppRunning: _toggleAppRunning,
        onRequestPermissions: requestPermissions,
      ),
    );
  }
}
