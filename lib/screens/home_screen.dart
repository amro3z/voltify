import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voltify/notification/local_service.dart';

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
  bool _isInitializing = false; // لمنع الـ Race Condition
  BatteryState _batteryState = BatteryState.unknown;
  late StreamSubscription<BatteryState> _batteryStateSubscription;
  Timer? _batteryInfoTimer;
  late String currentTimeZone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    requestPermissions();
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      // تهيئة SharedPreferences
      data = await SharedPreferences.getInstance();
      setState(() {
        appIsRunning = data.getBool('appIsRunning') ?? false;
        _prefsReady = true;
      });

      // تحديث الـ TimeZone
      final String timezone = await FlutterTimezone.getLocalTimezone();
      if (!mounted) return;
      setState(() {
        currentTimeZone = timezone;
        data.setString('currentTimeZone', timezone);
      });

      // تحديث حالة البطارية
      await _updateBatteryInfo();

      // إعداد الـ Stream Subscription
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
        _updateBatteryState,
      );

      // إعداد التايمر
      _batteryInfoTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        if (!mounted || !_prefsReady) return;
        await _updateBatteryInfo();
      });
    } catch (e) {
      debugPrint("⚠️ خطأ أثناء التهيئة: $e");
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
      debugPrint("⚠️ خطأ فى تحديث بيانات البطارية: $e");
    }
  }

  Future<void> requestPermissions() async {
    try {
      // اطلب overlay: البلجن هيفتح صفحة الإعدادات لو مش متاحة
      final hadOverlay = await FlutterOverlayWindow.isPermissionGranted();
      if (!hadOverlay) {
        await FlutterOverlayWindow.requestPermission(); // هنرجع للتطبيق بعد السماح/الرفض
      }

      // اطلب Notification على أندرويد 13+ (مش بيفتح Settings دايمًا)
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      // systemAlertWindow (لو بتستخدمها فعلًا)
      if (await Permission.systemAlertWindow.isDenied) {
        await Permission.systemAlertWindow.request();
      }

      // DND access عن طريق خدمتك
      await LocalService.requestDndAccessIfNeeded();

      // مهم: ما تعملش أي تهيئة Plugins تقيلة هنا بعد الرجوع.
      // سيب إعادة الفحص والأكشن لـ didChangeAppLifecycleState -> resumed
    } catch (e) {
      debugPrint("⚠️ خطأ أثناء طلب الأذونات: $e");
    }
  }

  void _updateBatteryState(BatteryState state) {
    if (_batteryState == state || !_prefsReady) return;
    setState(() {
      _batteryState = state;
      data.setString('batteryState', state.toString());
    });
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
    }
  }

  String getBatteryStateText(BatteryState state) {
    switch (state) {
      case BatteryState.charging:
        return 'Charging';
      case BatteryState.discharging:
        return 'Discharging';
      case BatteryState.full:
        return 'Full';
      case BatteryState.connectedNotCharging:
        return 'Connected but not charging';
      default:
        return 'Unknown';
    }
  }

  Future<void> toggleAppRunning() async {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            IgnorePointer(child: Lottie.asset('assets/animation/wave.json')),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.07,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: const Text(
                  'Voltify',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'CustomFont',
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.2,
              left: MediaQuery.of(context).size.width * 0.1,
              right: MediaQuery.of(context).size.width * 0.1,
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  Text(
                    getBatteryStateText(_batteryState),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontFamily: 'CustomFont',
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  Text(
                    "Save Mode is ${_isInBatterySaveMode ? 'Enabled' : 'Disabled'}",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontFamily: 'CustomFont',
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  CircularPercentIndicator(
                    radius: 120.0,
                    lineWidth: 13.0,
                    animation: false,
                    percent: _batteryLevel / 100,
                    center: Text(
                      "$_batteryLevel%",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'CustomFont',
                      ),
                    ),
                    footer: const Padding(
                      padding: EdgeInsets.only(top: 32.0),
                      child: Text(
                        "Battery Level",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: 'CustomFont',
                        ),
                      ),
                    ),
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: _batteryLevel < 30
                        ? Colors.red
                        : _batteryLevel < 60
                        ? Colors.orange
                        : Colors.green,
                  ),
                  const SizedBox(height: 20),
                  if (!_prefsReady)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: toggleAppRunning,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          appIsRunning ? 'Stop' : 'Start',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontFamily: 'CustomFont',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
