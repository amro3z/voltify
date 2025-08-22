import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voltify/screens/home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Future<void> _showIndicatorThenGoHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_welcome', true);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'indicator',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return Material(
          color: Colors.black.withOpacity(0.6),
          child: Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Lottie.asset('assets/animation/indicator.json'),
            ),
          ),
        );
      },
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.of(context).pop(); // اقفل الدايالوج
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.37,
            left: MediaQuery.of(context).size.width * 0.4,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Voltify',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'CustomFont',
                  ),
                  softWrap: true,
                ),
                Divider(
                  color: Colors.white,
                  thickness: 2,
                  endIndent: MediaQuery.of(context).size.width * 0.1,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                const Text(
                  'This app notifies you when the power comes back by detecting your phone starts charging.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'CustomFont',
                  ),
                  softWrap: true,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _showIndicatorThenGoHome,
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IgnorePointer(child: Lottie.asset('assets/animation/side.json')),
        ],
      ),
    );
  }
}
