import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ZlapPradApp());
}

class ZlapPradApp extends StatelessWidget {
  const ZlapPradApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Złap Prąd!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A10),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}
