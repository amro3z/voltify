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
  Offset _position = const Offset(15, 400);
  double _widgetHeight = 200.0; // يمكنك تغييره هنا حسب الحاجة

  Future<void> _closeOverlay() async {
    try {
      await WorkManagerHandler.closeOverlay();
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      print("❌ Error closing overlay: $e");
    }
  }

  Widget card() {
    return Container(
      height: _widgetHeight, // استخدام الارتفاع المتغير
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        gradient: RadialGradient(
          colors: [Colors.black, Colors.yellow[200]!],
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
              height: _widgetHeight, // ارتفاع ديناميكي
              child: Draggable(
                feedback: Material(color: Colors.transparent, child: card()),
                childWhenDragging: Opacity(opacity: 0.5, child: card()),
                onDragEnd: (details) {
                  setState(() {
                    double newX = details.offset.dx;
                    double newY = details.offset.dy;

                    // قيود لمنع الخروج عن الشاشة مع الأخذ بالحسا
                    newX = newX.clamp(0.0, screenSize.width - widgetWidth);
                    newY = newY.clamp(0.0, screenSize.height - _widgetHeight);

                    _position = Offset(newX, newY);
                  });
                },
                child: card(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
