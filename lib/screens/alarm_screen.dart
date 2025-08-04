import 'package:animated_analog_clock/animated_analog_clock.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slide_to_act/slide_to_act.dart';

class AlarmScreen extends StatefulWidget {
  final String currentTimeZone;
  const AlarmScreen({super.key, required this.currentTimeZone});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  late String currentTimeZone;
  late SharedPreferences data;
  final GlobalKey<SlideActionState> _key = GlobalKey<SlideActionState>();
  @override
  void initState() {
    super.initState();
    currentTimeZone = widget.currentTimeZone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Alarm',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'CustomFont',
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.07),
          Center(
            child: AnimatedAnalogClock(
              location: currentTimeZone,
              hourHandColor: Colors.white,
              minuteHandColor: Colors.white,
              secondHandColor: Colors.lightGreen,
              centerDotColor: Colors.lightGreen,
              hourDashColor: Colors.white,
              minuteDashColor: Colors.lightGreenAccent,
              dialType: DialType.numberAndDashes,
              numberColor: Colors.lightGreenAccent,
              size: MediaQuery.of(context).size.width * 0.8,
              backgroundGradient: const RadialGradient(
                colors: [Colors.black, Colors.lightGreenAccent],
                center: Alignment.center,
                radius: 1,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          Text(
            "Time Zone: $currentTimeZone",
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontFamily: 'CustomFont',
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          Text(
            "Wake up! Power has been restored!",
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontFamily: 'CustomFont',
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.06),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SlideAction(
              key: _key,
              sliderButtonIconSize: MediaQuery.of(context).size.height * 0.03,
              sliderButtonIconPadding: 12,
              sliderButtonYOffset: 0,
              sliderRotate: true,
              enabled: true,
              height: MediaQuery.of(context).size.height * 0.06,
              textColor: Colors.white,
              innerColor: Colors.green,
              outerColor: Colors.black,
              borderRadius: 52,
              elevation: 0,
              animationDuration: const Duration(milliseconds: 400),
              reversed: false,
              alignment: Alignment.center,
              submittedIcon: const Icon(Icons.check),
              onSubmit: () async {
                _key.currentState?.reset();
                Navigator.pop(context);
              },
              sliderButtonIcon: const Icon(Icons.arrow_forward),
              child: const Text(
                "Slide to Dismiss and wake up!",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontFamily: 'CustomFont',
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.17),
          Text(
            "Dont forget to turn off Voltify!",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.lightGreen,
              fontFamily: 'CustomFont',
            ),
          ),
        ],
      ),
    );
  }
}
