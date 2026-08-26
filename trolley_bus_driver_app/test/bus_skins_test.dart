import 'package:flutter_test/flutter_test.dart';

import 'package:trolley_bus_driver/achievements.dart';
import 'package:trolley_bus_driver/bus_skins.dart';

/// Pilnuje danych skinów - jak achievements_test.dart, żeby przy edycji nie
/// zgubić języka, nie zostawić pustego pola, ani nie odwołać się do
/// nieistniejącego osiągnięcia w requiresAchievement.
void main() {
  const languages = ['pl', 'en', 'de', 'fr'];

  test('lista skinów nie jest pusta i zaczyna się od klasycznego, odblokowanego od razu', () {
    expect(kBusSkins, isNotEmpty);
    expect(kBusSkins.first.id, kClassicBusSkin.id);
    expect(kBusSkins.first.requiresAchievement, isNull);
  });

  test('każdy skin ma nazwę we wszystkich językach', () {
    for (final s in kBusSkins) {
      for (final lang in languages) {
        final name = s.name[lang];
        expect(name, isNotNull, reason: 'brak nazwy "$lang" dla "${s.id}"');
        expect(name!.trim(), isNotEmpty, reason: 'pusta nazwa "$lang" dla "${s.id}"');
      }
    }
  });

  test('identyfikatory skinów się nie powtarzają', () {
    final ids = kBusSkins.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'zduplikowany identyfikator skina');
  });

  test('każdy wymagany achievement istnieje na liście osiągnięć', () {
    final achievementIds = kAchievements.map((a) => a.id).toSet();
    for (final s in kBusSkins) {
      final req = s.requiresAchievement;
      if (req == null) continue;
      expect(achievementIds.contains(req), isTrue, reason: '"${s.id}" wymaga nieistniejącego osiągnięcia "$req"');
    }
  });

  test('nameFor spada na polski przy nieznanym języku', () {
    final s = kBusSkins.first;
    expect(s.nameFor('es'), s.name['pl']);
  });
}
