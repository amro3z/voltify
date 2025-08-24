import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({
    super.key,
    required this.prefsReady,
    required this.batteryLevel,
    required this.batteryState,
    required this.isInBatterySaveMode,
    required this.appIsRunning,
    required this.onToggleAppRunning,
    required this.onRequestPermissions,
  });

  final bool prefsReady;
  final int batteryLevel;
  final BatteryState batteryState;
  final bool isInBatterySaveMode;
  final bool appIsRunning;

  final Future<void> Function() onToggleAppRunning;
  final Future<void> Function() onRequestPermissions;

  String _batteryStateText(BatteryState state) {
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
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Center(
      child: Stack(
        children: [
          IgnorePointer(child: Lottie.asset('assets/animation/wave.json')),
          Padding(
            padding: EdgeInsets.only(top: h * 0.07),
            child: const Align(
              alignment: Alignment.topCenter,
              child: Text(
                'Voltify',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'CustomFont',
                ),
              ),
            ),
          ),
          Positioned(
            top: h * 0.2,
            left: w * 0.1,
            right: w * 0.1,
            child: Column(
              children: [
                SizedBox(height: h * 0.03),
                Text(
                  _batteryStateText(batteryState),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: 'CustomFont',
                  ),
                ),
                SizedBox(height: h * 0.03),
                Text(
                  "Save Mode is ${isInBatterySaveMode ? 'Enabled' : 'Disabled'}",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: 'CustomFont',
                  ),
                ),
                SizedBox(height: h * 0.05),
                CircularPercentIndicator(
                  radius: 120.0,
                  lineWidth: 13.0,
                  animation: false,
                  percent: (batteryLevel.clamp(0, 100)) / 100,
                  center: Text(
                    "$batteryLevel%",
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
                  progressColor: batteryLevel < 30
                      ? Colors.red
                      : batteryLevel < 60
                      ? Colors.orange
                      : Colors.green,
                ),
                const SizedBox(height: 20),
                if (!prefsReady)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        await onToggleAppRunning();
                        await onRequestPermissions();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        appIsRunning ? 'Stop' : 'Start',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.red,
                          fontFamily: 'CustomFont',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
