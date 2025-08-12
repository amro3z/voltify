import 'package:animated_analog_clock/animated_analog_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
// import 'package:audioplayers/audioplayers.dart';
import 'package:voltify/background%20service/work_manager.dart';

class AlarmWidget extends StatefulWidget {
  const AlarmWidget({super.key});

  @override
  State<AlarmWidget> createState() => _AlarmWidgetState();
}

class _AlarmWidgetState extends State<AlarmWidget> {
  @override
  void initState() {
    super.initState();

    // Add a small delay to ensure the overlay is properly displayed
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _closeOverlay() async {
    try {
      await WorkManagerHandler.closeOverlay(); // Notify work manager
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      print("❌ Error closing overlay: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        height: 400,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          gradient: RadialGradient(
            colors: [Colors.black, Colors.lightGreen[200]!],
            center: Alignment.center,
            radius: 2,
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: AnimatedAnalogClock(
                location: "Africa/Cairo",
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
              children: const [
                Text(
                  "Wake Up!",
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontFamily: 'CustomFont',
                  ),
                ),
                Text(
                  "The Electric Alarm",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'CustomFont',
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
        ),
      ),
    );
  }
}
