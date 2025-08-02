import 'package:flutter/material.dart';
import 'package:voltify/screens/home_screen.dart';

void main() {
  
  runApp(Init());
}
class Init extends StatelessWidget {
  const Init({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Voltify',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}