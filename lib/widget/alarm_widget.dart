import 'package:animated_analog_clock/animated_analog_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:voltify/background%20service/work_manager.dart';

class AlarmWidget extends StatefulWidget {
  const AlarmWidget({super.key});

  @override
  State<AlarmWidget> createState() => _AlarmWidgetState();
}

class _AlarmWidgetState extends State<AlarmWidget> {
  Offset _position = Offset.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_position == Offset.zero) {
      final screenSize = MediaQuery.of(context).size;
      const widgetHeight = 250.0;
      final widgetWidth = screenSize.width * 0.9;

      // For overlay windows, use a fixed offset from top to avoid status bar
      // Typical status bar height is around 24-48dp, so we'll use 60 to be safe
      const statusBarOffset = 60.0;

      _position = Offset(
        (screenSize.width - widgetWidth) / 2, // Center horizontally
        statusBarOffset +
            (screenSize.height - statusBarOffset - widgetHeight) /
                2, // Center vertically below status bar
      );
    }
  }

  Future<void> _closeOverlay() async {
    try {
      await WorkManagerHandler.closeOverlay();
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      print("❌ Error closing overlay: $e");
    }
  }

  Widget _buildAlarmContent(BuildContext context) {
    return Row(
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
              "Wake Up!⚡",
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(
            top: _position.dy,
            child: Draggable(
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  height: 250,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    gradient: RadialGradient(
                      colors: [Colors.black, Colors.lightGreenAccent[200]!],
                      center: Alignment.center,
                      radius: 2,
                    ),
                  ),
                  child: _buildAlarmContent(context),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: Container(
                  height: 250,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    gradient: RadialGradient(
                      colors: [Colors.black, Colors.lightGreenAccent[200]!],
                      center: Alignment.center,
                      radius: 2,
                    ),
                  ),
                  child: _buildAlarmContent(context),
                ),
              ),
              onDragEnd: (details) {
                setState(() {
                  // Ensure the widget stays within screen bounds
                  final screenSize = MediaQuery.of(context).size;
                  const widgetHeight = 250.0;
                  final widgetWidth = screenSize.width * 0.9;

                  // Use fixed offsets for overlay windows
                  const statusBarOffset = 20.0;
                  const navBarOffset =
                      20.0; // Space for navigation bar at bottom

                  double newX = details.offset.dx;
                  double newY = details.offset.dy;

                  // Constrain X position
                  newX = newX.clamp(0.0, screenSize.width - widgetWidth);

                  // Constrain Y position with fixed offsets
                  newY = newY.clamp(
                    statusBarOffset,
                    screenSize.height - widgetHeight - navBarOffset,
                  );

                  _position = Offset(newX, newY);
                });
              },
              child: Container(
                height: 250,
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  gradient: RadialGradient(
                    colors: [Colors.black, Colors.lightGreenAccent[200]!],
                    center: Alignment.center,
                    radius: 2,
                  ),
                ),
                child: _buildAlarmContent(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
