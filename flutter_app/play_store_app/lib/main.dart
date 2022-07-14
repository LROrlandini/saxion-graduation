import 'package:flutter/material.dart';
import 'package:splashscreen/splashscreen.dart';
import 'start_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
          seconds: 3,
          navigateAfterSeconds: const StartScreen(),
          image: Image.asset("icons/aemics-logo.png"),
          photoSize: 120.0,
          backgroundColor: Colors.blue[50],
        ));
  }
}
