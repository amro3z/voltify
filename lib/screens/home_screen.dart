import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voltify/screens/alarm_screen.dart';

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
  static const platform = MethodChannel('voltify/intent');
  bool _pendingOpenAlarm = false;

  @override
  void initState() {
    super.initState();
    log('🔥 Initializing HomeScreen');
    initApp();
    platform.setMethodCallHandler((call) async {
      log('🔥 MethodChannel handler called: ${call.method}');
      if (call.method == "onNewIntent") {
        final bool shouldOpenAlarm = call.arguments as bool;
        log('🔥 Received onNewIntent: shouldOpenAlarm = $shouldOpenAlarm');
        if (shouldOpenAlarm && mounted) {
          log('🔥 Navigating to AlarmScreen from onNewIntent');
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) =>
                  AlarmScreen(currentTimeZone: currentTimeZone),
            ),
          );
        } else {
          log(
            '🔥 Not navigating: shouldOpenAlarm = $shouldOpenAlarm, mounted = $mounted',
          );
          if (shouldOpenAlarm) {
            _pendingOpenAlarm = true; // Store pending intent if not mounted
          }
        }
      }
      return null;
    });
    // Check initial intent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkIntentAndOpenAlarm(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pendingOpenAlarm && mounted) {
      log(
        '🔥 Navigating to AlarmScreen from pending intent in didChangeDependencies',
      );
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => AlarmScreen(currentTimeZone: currentTimeZone),
        ),
      );
      _pendingOpenAlarm = false;
    }
  }

  Future<void> initApp() async {
    data = await SharedPreferences.getInstance();
    setState(() {
      appIsRunning = data.getBool('appIsRunning') ?? false;
    });

    currentTimeZone = await FlutterTimezone.getLocalTimezone();
    await data.setString('currentTimeZone', currentTimeZone);

    _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
      _updateBatteryState,
    );
    _batteryLevel = await _battery.batteryLevel;
    _isInBatterySaveMode = await _battery.isInBatterySaveMode;
    _battery.batteryState.then(_updateBatteryState);

    _batteryInfoTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final level = await _battery.batteryLevel;
      final mode = await _battery.isInBatterySaveMode;
      if (level != _batteryLevel || mode != _isInBatterySaveMode) {
        setState(() {
          _batteryLevel = level;
          _isInBatterySaveMode = mode;
        });
      }
    });

    setState(() {});
  }

  void _updateBatteryState(BatteryState state) {
    if (_batteryState == state) return;
    setState(() {
      _batteryState = state;
      data.setString('batteryState', state.toString());
    });
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

  Future<void> writeStateFile(Map<String, String> params) async {
    final file = File(params['path']!);
    await file.writeAsString(params['value']!);
  }

  void toggleAppRunning() async {
    setState(() {
      appIsRunning = !appIsRunning;
    });
    await data.setBool('appIsRunning', appIsRunning);
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/state.txt';
    try {
      await compute(writeStateFile, {
        'path': path,
        'value': appIsRunning ? '1' : '0',
      });
      log('[FILE] Saved appIsRunning = ${appIsRunning ? '1' : '0'}');
      log('[FILE] File path = $path');
      log('[FILE] File exists: ${await File(path).exists()}');
    } catch (e) {
      log('[FILE] ❌ Error saving appIsRunning: $e');
    }
  }

  Future<void> checkIntentAndOpenAlarm(BuildContext context) async {
    try {
      final bool shouldOpenAlarm = await platform.invokeMethod('checkIntent');
      log('🔥 Checking intent: shouldOpenAlarm = $shouldOpenAlarm');
      if (shouldOpenAlarm && mounted) {
        log('🔥 Navigating to AlarmScreen from checkIntent');
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => AlarmScreen(currentTimeZone: currentTimeZone),
          ),
        );
      } else {
        log(
          '🔥 Not navigating: shouldOpenAlarm = $shouldOpenAlarm, mounted = $mounted',
        );
        if (shouldOpenAlarm) {
          _pendingOpenAlarm = true; // Store pending intent if not mounted
        }
      }
    } catch (e) {
      log('❌ Error checking intent: $e');
    }
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
