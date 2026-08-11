import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trolley_bus_driver/game_screen.dart';
import 'package:trolley_bus_driver/l10n/generated/app_localizations.dart';

/// Renders the start screen in each shipped language on the narrowest phone
/// width we claim to support, with a two-digit saved stage (the longest
/// realistic "Kontynuuj/Continue/Continuer/Weiter · Etap NN" label) - the
/// case most likely to overflow a pill-shaped button that sizes to its text.
void main() {
  testWidgets('start screen renders without overflow in every locale', (tester) async {
    SharedPreferences.setMockInitialValues({'zlapprad_saved_stage': 27});

    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GameScreen(),
        ),
      );
      // Lets the async SharedPreferences load (savedStage) resolve and its
      // notifyListeners() rebuild land, without waiting on the game's own
      // animation ticker, which never settles on its own.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow or render error for locale ${locale.languageCode} at 320px width',
      );

      final loc = AppLocalizations.of(tester.element(find.byType(GameScreen)))!;
      // ignore: avoid_print
      print('[${locale.languageCode}] continueStage="${loc.continueStage(27)}" '
          'newGame="${loc.newGame}" closeApp="${loc.closeApp}" '
          'quitConfirm="${loc.quitConfirm}"');
    }
  });
}
