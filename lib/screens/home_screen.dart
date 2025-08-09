import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voltify/notification/local_service.dart';
import 'package:voltify/background%20service/work_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Battery _battery = Battery();
  late SharedPreferences data;

  bool _isInBatterySaveMode = false;
  int _batteryLevel = 0;
  bool appIsRunning = false;
  BatteryState _batteryState = BatteryState.unknown;
  late StreamSubscription<BatteryState> _batteryStateSubscription;
  Timer? _batteryInfoTimer;
  late String currentTimeZone;
  @override
  void initState() {
    super.initState();

    // ننتظر تهيئة SharedPreferences
    SharedPreferences.getInstance()
        .then((sp) {
          data = sp;
          setState(() {
            appIsRunning = data.getBool('appIsRunning') ?? false;
          });

          // نحدث الـ TimeZone بعد تهيئة data
          FlutterTimezone.getLocalTimezone().then((String timezone) {
            setState(() {
              currentTimeZone = timezone;
              data.setString('currentTimeZone', timezone);
            });
          });

          // نحدث حالة البطارية بعد تهيئة data
          _battery.batteryState.then(_updateBatteryState);
          _battery.batteryLevel.then(
            (level) => setState(() => _batteryLevel = level),
          );
          _battery.isInBatterySaveMode.then(
            (mode) => setState(() => _isInBatterySaveMode = mode),
          );

          _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
            _updateBatteryState,
          );

          _batteryInfoTimer = Timer.periodic(const Duration(seconds: 5), (
            _,
          ) async {
            // زيادة المدة
            if (!mounted) return; // لو الـ Widget مات، يرجع
            final level = await _battery.batteryLevel;
            final mode = await _battery.isInBatterySaveMode;
            if (mounted) {
              setState(() {
                _batteryLevel = level;
                _isInBatterySaveMode = mode;
              });
            }
          });
        })
        .catchError((e) {
          print("Error initializing SharedPreferences: $e");
        });
  }

  void _updateBatteryState(BatteryState state) {
    if (_batteryState == state) return;
    setState(() {
      _batteryState = state;
      data.setString('batteryState', state.toString());
    });

    // Trigger work manager to check charging status when battery state changes
    WorkManagerHandler.triggerChargingCheck();
  }

  @override
  void dispose() {
    _batteryStateSubscription.cancel();
    _batteryInfoTimer?.cancel();
    super.dispose();
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

  void toggleAppRunning() async {
    setState(() {
      appIsRunning = !appIsRunning;
    });
    await data.setBool('appIsRunning', appIsRunning);

    // Update work manager app running status
    WorkManagerHandler.setAppRunning(appIsRunning);

    // Trigger work manager to check charging status immediately
    await WorkManagerHandler.triggerChargingCheck();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Voltify',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'CustomFont',
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
            animationDuration: 2000,
            animateFromLastPercent: true,
            animation: true,
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
          ElevatedButton(
            onPressed: () {
              toggleAppRunning();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              // Test overlay manually
              if (await FlutterOverlayWindow.isPermissionGranted()) {
                await FlutterOverlayWindow.showOverlay(
                  height: 400,
                  overlayTitle: "Voltify Alarm",
                  overlayContent: "Test Overlay",
                  flag: OverlayFlag.focusPointer,
                );
              } else {
                print("❌ Overlay permission not granted");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              "Test Overlay",
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontFamily: 'CustomFont',
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'This app monitors the battery status and notifies you when the electricity comes back.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.lightGreen,
              fontFamily: 'CustomFont',
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
