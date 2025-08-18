import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _prefsReady = false; // للتأكد إننا ما نستخدمش data قبل التهيئة
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
            _prefsReady = true;
          });

          // نحدث الـ TimeZone بعد تهيئة data
          FlutterTimezone.getLocalTimezone().then((String timezone) {
            if (!mounted) return;
            setState(() {
              currentTimeZone = timezone;
              data.setString('currentTimeZone', timezone);
            });
          });

          // نحدث حالة البطارية بعد تهيئة data
          _battery.batteryState.then(_updateBatteryState);
          _battery.batteryLevel.then(
            (level) => mounted ? setState(() => _batteryLevel = level) : null,
          );
          _battery.isInBatterySaveMode.then(
            (mode) =>
                mounted ? setState(() => _isInBatterySaveMode = mode) : null,
          );

          _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
            _updateBatteryState,
          );

          _batteryInfoTimer = Timer.periodic(const Duration(seconds: 5), (
            _,
          ) async {
            if (!mounted || !_prefsReady) return;
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
          debugPrint("Error initializing SharedPreferences: $e");
        });
  }

  void _updateBatteryState(BatteryState state) {
    if (_batteryState == state) return;
    setState(() {
      _batteryState = state;
      data.setString('batteryState', state.toString());
    });

    // Note: Overlay control is now handled by PowerConnectionReceiver
    // for better background support. This prevents conflicts between
    // Flutter battery listener and native broadcast receiver.

    // Just update the UI state, don't control overlay here
    // The PowerConnectionReceiver will handle overlay show/hide
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
      appBar: AppBar(
        title: const Text(
          'Voltify',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'CustomFont',
          ),
        ),
        centerTitle: true,
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
          if (!_prefsReady)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else
            ElevatedButton(
              onPressed: () {
                toggleAppRunning();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
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
