import 'package:animated_analog_clock/animated_analog_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:audioplayers/audioplayers.dart';

class AlarmWidget extends StatefulWidget {
  const AlarmWidget({super.key});

  @override
  State<AlarmWidget> createState() => _AlarmWidgetState();
}

class _AlarmWidgetState extends State<AlarmWidget> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _startAlarm();

    // Add a small delay to ensure the overlay is properly displayed
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _startAlarm() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);

    // إعدادات لتشغيل الصوت كـ Alarm
    final ctx = AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.alarm, // مهم جدًا
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
    );

    await _audioPlayer.setAudioContext(ctx);

    await _audioPlayer.play(
      AssetSource("sounds/sound.wav"), // تأكد من المسار في pubspec.yaml
    );
  }

  Future<void> _stopAlarm() async {
    await _audioPlayer.stop();
  }

  @override
  void dispose() {
    _stopAlarm();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
              padding: const EdgeInsets.only(left: 8.0),
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
            SizedBox(width: MediaQuery.of(context).size.width * 0.08),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "Wake Up!",
                  style: TextStyle(
                    fontSize: 24,
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
            SizedBox(width: MediaQuery.of(context).size.width * 0.15),
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
                onPressed: () async {
                  await _stopAlarm();
                  await FlutterOverlayWindow.closeOverlay();
                },
                icon: const Icon(Icons.cancel, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
