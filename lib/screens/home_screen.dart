import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:voltify/screens/alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Battery _battery = Battery();

  bool _isInBatterySaveMode = false;
  int _batteryLevel = 0;
  bool appIsRunning = false;
  BatteryState _batteryState = BatteryState.unknown;

  late StreamSubscription<BatteryState> _batteryStateSubscription;
  Timer? _batteryInfoTimer; // ← التايمر
  late String currentTimeZone;
  @override
  void initState() {
    super.initState();
    FlutterTimezone.getLocalTimezone().then((String timezone) {
      setState(() {
        currentTimeZone = timezone;
      });
    });
    // قراءة الحالة الحالية مرة واحدة
    _battery.batteryState.then(_updateBatteryState);
    _battery.batteryLevel.then((level) => _batteryLevel = level);
    _battery.isInBatterySaveMode.then((mode) => _isInBatterySaveMode = mode);

    // متابعة تغيّرات حالة الشحن
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
      _updateBatteryState,
    );

    // التايمر كل 3 ثواني
    _batteryInfoTimer = Timer.periodic(Duration(seconds: 3), (_) async {
      final level = await _battery.batteryLevel;
      final mode = await _battery.isInBatterySaveMode;

      if (level != _batteryLevel || mode != _isInBatterySaveMode) {
        setState(() {
          _batteryLevel = level;
          _isInBatterySaveMode = mode;
        });
      }
    });
  }

  void _updateBatteryState(BatteryState state) {
    if (_batteryState == state) return;
    setState(() {
      _batteryState = state;
    });
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

  @override
  void dispose() {
    _batteryStateSubscription.cancel();
    _batteryInfoTimer?.cancel();
    super.dispose();
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                getBatteryStateText(_batteryState),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontFamily: 'CustomFont',
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "Save Mode is ${_isInBatterySaveMode ? 'Enabled' : 'Disabled'}",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontFamily: 'CustomFont',
                ),
              ),
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
            footer: Padding(
              padding: const EdgeInsets.only(top: 32.0),
              child: Text(
                "Battery Level",
                style: const TextStyle(
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
          SizedBox(height: MediaQuery.of(context).size.height * 0.025),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  appIsRunning = true;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AlarmScreen(currentTimeZone: currentTimeZone),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 8.0,
                ),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                appIsRunning ? 'Stop' : 'Start ',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontFamily: 'CustomFont',
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Text(
            'This app monitors the battery status and notifies you ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.lightGreen,
              fontFamily: 'CustomFont',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 8, bottom: 16.0),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'when the electricity comes back.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.lightGreen,
                  fontFamily: 'CustomFont',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
