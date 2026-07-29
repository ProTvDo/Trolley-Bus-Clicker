import 'package:flutter_test/flutter_test.dart';

import 'package:trolley_bus_driver/gdynia_stops.dart';

/// Pilnuje danych przystanków - to plik przeznaczony do ręcznej edycji, więc
/// łatwo przy okazji zgubić tłumaczenie albo zostawić pustą ciekawostkę, a
/// tabliczka w grze wyświetliłaby wtedy pustkę.
void main() {
  const languages = ['pl', 'en', 'de', 'fr'];

  test('lista przystanków nie jest pusta', () {
    expect(kGdyniaStops, isNotEmpty);
  });

  test('każdy przystanek ma nazwę i ciekawostkę we wszystkich językach', () {
    for (final stop in kGdyniaStops) {
      expect(stop.name.trim(), isNotEmpty, reason: 'pusta nazwa przystanku');
      for (final lang in languages) {
        final story = stop.story[lang];
        expect(story, isNotNull, reason: 'brak języka "$lang" dla "${stop.name}"');
        expect(story!.trim(), isNotEmpty, reason: 'pusta ciekawostka "$lang" dla "${stop.name}"');
      }
    }
  });

  test('nazwy przystanków się nie powtarzają', () {
    final names = kGdyniaStops.map((s) => s.name).toList();
    expect(names.toSet().length, names.length, reason: 'zduplikowana nazwa przystanku');
  });

  test('storyFor spada na polski przy nieznanym języku', () {
    final stop = kGdyniaStops.first;
    expect(stop.storyFor('es'), stop.story['pl']);
  });
}
