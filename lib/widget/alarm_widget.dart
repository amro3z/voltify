import 'dart:async';
import 'package:animated_analog_clock/animated_analog_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmWidget extends StatefulWidget {
  const AlarmWidget({super.key});

  @override
  State<AlarmWidget> createState() => _AlarmWidgetState();
}

class _AlarmWidgetState extends State<AlarmWidget> {
  String? _timezone;
  bool? _appIsRunning;
  int? _lastActiveTs;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _resolveTimezone();
    _loadAppRunning();
    // تحديث دوري كل ثانيتين عشان نتأكد القيمة بتتغير فعلاً
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadAppRunning();
    });
  }

  Future<void> _loadAppRunning() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool('appIsRunning');
      final ts = prefs.getInt('last_active_ts');
      if (mounted) {
        setState(() {
          _appIsRunning = val;
          _lastActiveTs = ts;
        });
      }
    } catch (e) {
      debugPrint('Failed to load appIsRunning: $e');
      if (mounted) setState(() => _appIsRunning = null);
    }
  }

  Future<void> _resolveTimezone() async {
    try {
      final String tzName = await FlutterTimezone.getLocalTimezone();
      if (mounted) {
        setState(() => _timezone = tzName);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get timezone, fallback UTC: $e');
      if (mounted) setState(() => _timezone = 'Africa/Cairo');
    }
  }

  Offset _position = const Offset(15, 400);
  final double _widgetHeight = 200.0;

  Future<void> _closeOverlay() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      debugPrint("❌ Error closing overlay: $e");
    }
  }

  Widget card() {
    return Container(
      height: _widgetHeight,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        gradient: RadialGradient(
          colors: [Colors.black, Colors.blue],
          center: Alignment.center,
          radius: 2,
        ),
      ),
      child: _buildAlarmContent(context),
    );
  }

  Widget _buildAlarmContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6.0),
          child: AnimatedAnalogClock(
            location: _timezone,
            hourHandColor: Colors.white,
            minuteHandColor: Colors.white,
            secondHandColor: Colors.lightGreen,
            centerDotColor: Colors.lightGreen,
            hourDashColor: Colors.white,
            minuteDashColor: Colors.lightGreenAccent,
            dialType: DialType.numberAndDashes,
            numberColor: Colors.black,
            extendHourHand: true,
            extendMinuteHand: true,
            extendSecondHand: true,
            size: MediaQuery.of(context).size.width * 0.3,
            backgroundGradient: RadialGradient(
              colors: [Colors.black, Colors.lightGreen[200]!],
              center: Alignment.center,
              radius: 1,
            ),
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.04),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Wake Up!⚡",
              style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontFamily: 'CustomFont',
              ),
            ),
            const Text(
              "The Electric Alarm",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'CustomFont',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'appIsRunning: ${_appIsRunning == null
                  ? '...'
                  : _appIsRunning == true
                  ? 'true'
                  : 'false'}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontFamily: 'CustomFont',
              ),
            ),
            if (_lastActiveTs != null)
              Text(
                'lastActive: ${DateTime.fromMillisecondsSinceEpoch(_lastActiveTs!).toLocal().toIso8601String().substring(11, 19)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                  fontFamily: 'CustomFont',
                ),
              ),
            TextButton(
              onPressed: _loadAppRunning,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 22),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(fontSize: 11, color: Colors.lightGreenAccent),
              ),
            ),
          ],
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.09),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 20,
                spreadRadius: 0.4,
              ),
            ],
          ),
          child: IconButton(
            onPressed: _closeOverlay,
            icon: const Icon(Icons.cancel, color: Colors.white, size: 30),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final widgetWidth = screenSize.width * 0.9;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: _position.dy,
            left: _position.dx,
            child: SizedBox(
              width: widgetWidth,
              height: _widgetHeight,
              child: Draggable(
                feedback: Material(color: Colors.transparent, child: card()),
                childWhenDragging: Opacity(opacity: 0.5, child: card()),
                onDragEnd: (details) {
                  setState(() {
                    double newX = details.offset.dx;
                    double newY = details.offset.dy;
                    newX = newX.clamp(0.0, screenSize.width - widgetWidth);
                    newY = newY.clamp(0.0, screenSize.height - _widgetHeight);

                    _position = Offset(newX, newY);
                  });
                },
                child: card(),
              ),
            ),
          ),
          // Test button to trigger notification manually
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
