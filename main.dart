import 'package:flutter/material.dart';
import 'package:voiceassistant/home_page.dart';
import 'package:voiceassistant/pallete.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Assistant',
      theme: ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Pallete.whiteColor,
        appBarTheme: const AppBarTheme(backgroundColor: Pallete.whiteColor),
      ),
      home: const HomePage(),
    );
  }
}
