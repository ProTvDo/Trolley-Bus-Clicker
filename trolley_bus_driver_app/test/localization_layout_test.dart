import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trolley_bus_driver/achievements.dart';
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

  testWidgets('achievements screen renders without overflow in every locale', (tester) async {
    // One unlocked (renders icon + name + description) and the rest locked
    // (renders the lock placeholder) - exercises both row states, which have
    // different text lengths and are equally capable of overflowing.
    SharedPreferences.setMockInitialValues({
      'zlapprad_achievements': [kAchievements.first.id],
    });

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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final loc = AppLocalizations.of(tester.element(find.byType(GameScreen)))!;
      await tester.tap(find.textContaining(loc.achievementsButton));
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow or render error on the achievements screen for locale ${locale.languageCode} at 320px width',
      );
    }
  });

  testWidgets('skins screen renders without overflow in every locale', (tester) async {
    // 'odkrywca' unlocks the 'eco' skin - exercises an unlocked, selectable
    // row alongside the still-locked ones, whose hint text ("Unlock: <full
    // achievement name>") is the longest new string this screen adds and
    // the most likely to overflow.
    SharedPreferences.setMockInitialValues({
      'zlapprad_achievements': ['odkrywca'],
    });

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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final loc = AppLocalizations.of(tester.element(find.byType(GameScreen)))!;
      await tester.tap(find.textContaining(loc.skinsButton));
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow or render error on the skins screen for locale ${locale.languageCode} at 320px width',
      );
    }
  });

  testWidgets('stops album screen renders without overflow in every locale', (tester) async {
    // One seen stop (renders name + full trivia text, the longest content
    // this screen shows) alongside the rest still locked.
    SharedPreferences.setMockInitialValues({
      'zlapprad_seen_stops': ['0'],
    });

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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final loc = AppLocalizations.of(tester.element(find.byType(GameScreen)))!;
      await tester.tap(find.textContaining(loc.stopsAlbumButton));
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow or render error on the stops album screen for locale ${locale.languageCode} at 320px width',
      );
    }
  });

  testWidgets('pause overlay renders without overflow in every locale', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final locale in AppLocalizations.supportedLocales) {
      // Keyed by locale so each iteration gets a fresh GameScreen State (and
      // fresh GameController) instead of Flutter reconciling it with the
      // previous iteration's - without this, the second locale would reuse
      // the first's already-playing/already-paused controller and never
      // show the start screen's Play button at all.
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey('pause-test-${locale.languageCode}'),
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final loc = AppLocalizations.of(tester.element(find.byType(GameScreen)))!;
      await tester.tap(find.text(loc.play));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The pause round button is the only '⏸' on screen before a pause is
      // active - the overlay's own '⏸' title only appears after this tap.
      await tester.tap(find.text('⏸'));
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow or render error on the pause overlay for locale ${locale.languageCode} at 320px width',
      );
    }
  });
}
