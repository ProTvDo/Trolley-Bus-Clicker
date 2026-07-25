import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_screen.dart';

/// Set via --dart-define=BUILD_NUMBER=... in CI (the Actions run number),
/// shown on the start screen so it's always obvious which APK is installed.
const String kBuildNumber = String.fromEnvironment('BUILD_NUMBER', defaultValue: 'dev');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const TrolleyBusDriverApp());
}

class TrolleyBusDriverApp extends StatelessWidget {
  const TrolleyBusDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trolley Bus Driver',
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
