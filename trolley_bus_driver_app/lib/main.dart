import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'game_screen.dart';
import 'l10n/generated/app_localizations.dart';

/// Set via --dart-define=BUILD_NUMBER=... in CI (the Actions run number),
/// shown on the start screen so it's always obvious which APK is installed.
const String kBuildNumber = String.fromEnvironment('BUILD_NUMBER', defaultValue: 'dev');

/// Player-facing update stamp in the start screen's bottom-left corner, so
/// players can tell at a glance that the game was updated. [kUpdateNumber] is
/// the store versionCode (1.0.1+2 -> "2"); [kUpdateDate] is the release date
/// as ISO yyyy-MM-dd, reformatted per the player's locale at display time.
/// Both are injected at build time via --dart-define.
const String kUpdateNumber = String.fromEnvironment('UPDATE_NUMBER', defaultValue: '1');
const String kUpdateDate = String.fromEnvironment('UPDATE_DATE', defaultValue: '');

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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Falls back to English for any device language we don't ship a
      // translation for, instead of Flutter's default (first supported
      // locale, which would otherwise silently be whichever ARB file
      // happens to sort first).
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == deviceLocale.languageCode) return supported;
          }
        }
        return const Locale('en');
      },
      home: const GameScreen(),
    );
  }
}
