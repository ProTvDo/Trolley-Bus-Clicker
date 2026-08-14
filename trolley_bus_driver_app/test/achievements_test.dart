import 'package:flutter_test/flutter_test.dart';

import 'package:trolley_bus_driver/achievements.dart';

/// Pilnuje danych osiągnięć - jak gdynia_stops_test.dart, żeby przy edycji
/// treści nie zgubić języka ani nie zostawić pustego pola.
void main() {
  const languages = ['pl', 'en', 'de', 'fr'];

  test('lista osiągnięć nie jest pusta', () {
    expect(kAchievements, isNotEmpty);
  });

  test('każde osiągnięcie ma ikonę, nazwę i opis we wszystkich językach', () {
    for (final a in kAchievements) {
      expect(a.icon.trim(), isNotEmpty, reason: 'pusta ikona dla "${a.id}"');
      for (final lang in languages) {
        final name = a.name[lang];
        final desc = a.description[lang];
        expect(name, isNotNull, reason: 'brak nazwy "$lang" dla "${a.id}"');
        expect(name!.trim(), isNotEmpty, reason: 'pusta nazwa "$lang" dla "${a.id}"');
        expect(desc, isNotNull, reason: 'brak opisu "$lang" dla "${a.id}"');
        expect(desc!.trim(), isNotEmpty, reason: 'pusty opis "$lang" dla "${a.id}"');
      }
    }
  });

  test('identyfikatory się nie powtarzają', () {
    final ids = kAchievements.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'zduplikowany identyfikator osiągnięcia');
  });

  test('nameFor/descriptionFor spadają na polski przy nieznanym języku', () {
    final a = kAchievements.first;
    expect(a.nameFor('es'), a.name['pl']);
    expect(a.descriptionFor('es'), a.description['pl']);
  });
}
