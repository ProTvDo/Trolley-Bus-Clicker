/// Osiągnięcia gry: definicje treści (ikona, nazwa, opis w 4 językach).
///
/// Stan odblokowania trzyma GameController (SharedPreferences, klucz
/// zlapprad_achievements) - ten plik to wyłącznie statyczna treść, tak samo
/// jak gdynia_stops.dart, żeby dało się ją poprawiać bez ruszania logiki gry.
library;

class Achievement {
  const Achievement({
    required this.id,
    required this.icon,
    required this.name,
    required this.description,
  });

  /// Stabilny identyfikator - używany jako klucz zapisu, nigdy nie zmieniać
  /// istniejącego id (zgubiłoby to postęp graczy, którzy je już odblokowali).
  final String id;
  final String icon;
  final Map<String, String> name;
  final Map<String, String> description;

  String nameFor(String languageCode) => name[languageCode] ?? name['pl']!;
  String descriptionFor(String languageCode) => description[languageCode] ?? description['pl']!;
}

const List<Achievement> kAchievements = [
  Achievement(
    id: 'pierwszy-przystanek',
    icon: '🚏',
    name: {'pl': 'Pierwszy przystanek', 'en': 'First Stop', 'de': 'Erste Haltestelle', 'fr': 'Premier arrêt'},
    description: {
      'pl': 'Dotarłeś do pierwszego przystanku.',
      'en': 'You reached your first stop.',
      'de': 'Du hast deine erste Haltestelle erreicht.',
      'fr': 'Vous avez atteint votre premier arrêt.',
    },
  ),
  Achievement(
    id: 'pierwsza-zwrotnica',
    icon: '🔀',
    name: {'pl': 'Pierwsza zwrotnica', 'en': 'First Switch', 'de': 'Erste Weiche', 'fr': 'Premier aiguillage'},
    description: {
      'pl': 'Ukończyłeś etap ze zwrotnicami.',
      'en': 'You completed a stage with switches.',
      'de': 'Du hast eine Etappe mit Weichen abgeschlossen.',
      'fr': 'Vous avez terminé une étape avec aiguillages.',
    },
  ),
  Achievement(
    id: 'unik',
    icon: '🚧',
    name: {'pl': 'Unik', 'en': 'Dodge', 'de': 'Ausweichmanöver', 'fr': 'Esquive'},
    description: {
      'pl': 'Ominąłeś przeszkodę blokującą zwrotnicę.',
      'en': 'You dodged an obstacle blocking a switch.',
      'de': 'Du bist einem Hindernis an einer Weiche ausgewichen.',
      'fr': 'Vous avez évité un obstacle bloquant un aiguillage.',
    },
  ),
  Achievement(
    id: 'bez-wypadku',
    icon: '🛡️',
    name: {'pl': 'Bez wypadku', 'en': 'Flawless', 'de': 'Unfallfrei', 'fr': 'Sans accroc'},
    description: {
      'pl': 'Ukończyłeś etap, nie tracąc ani jednego życia.',
      'en': 'You completed a stage without losing a life.',
      'de': 'Du hast eine Etappe ohne Lebensverlust abgeschlossen.',
      'fr': 'Vous avez terminé une étape sans perdre une vie.',
    },
  ),
  Achievement(
    id: 'idealna-jazda',
    icon: '⚡',
    name: {'pl': 'Idealna jazda', 'en': 'Perfect Run', 'de': 'Perfekte Fahrt', 'fr': 'Trajet parfait'},
    description: {
      'pl': 'Osiągnąłeś maksymalny mnożnik punktów x5.',
      'en': 'You reached the maximum x5 score multiplier.',
      'de': 'Du hast den maximalen x5-Punktemultiplikator erreicht.',
      'fr': 'Vous avez atteint le multiplicateur de score maximal x5.',
    },
  ),
  Achievement(
    id: 'maratonczyk',
    icon: '🏁',
    name: {'pl': 'Maratończyk', 'en': 'Marathoner', 'de': 'Marathonläufer', 'fr': 'Marathonien'},
    description: {
      'pl': 'Dotarłeś do etapu 10.',
      'en': 'You reached stage 10.',
      'de': 'Du hast Etappe 10 erreicht.',
      'fr': "Vous avez atteint l'étape 10.",
    },
  ),
  Achievement(
    id: 'weteran',
    icon: '🎖️',
    name: {'pl': 'Weteran torów', 'en': 'Veteran Driver', 'de': 'Veteran der Schienen', 'fr': 'Vétéran des rails'},
    description: {
      'pl': 'Dotarłeś do etapu 20.',
      'en': 'You reached stage 20.',
      'de': 'Du hast Etappe 20 erreicht.',
      'fr': "Vous avez atteint l'étape 20.",
    },
  ),
  Achievement(
    id: 'legenda',
    icon: '👑',
    name: {'pl': 'Legenda', 'en': 'Legend', 'de': 'Legende', 'fr': 'Légende'},
    description: {
      'pl': 'Dotarłeś do etapu 30.',
      'en': 'You reached stage 30.',
      'de': 'Du hast Etappe 30 erreicht.',
      'fr': "Vous avez atteint l'étape 30.",
    },
  ),
  Achievement(
    id: 'odkrywca',
    icon: '🗺️',
    name: {'pl': 'Odkrywca', 'en': 'Explorer', 'de': 'Entdecker', 'fr': 'Explorateur'},
    description: {
      'pl': 'Zobaczyłeś 5 różnych przystanków Gdyni.',
      'en': "You've seen 5 different Gdynia stops.",
      'de': 'Du hast 5 verschiedene Haltestellen in Gdynia gesehen.',
      'fr': 'Vous avez vu 5 arrêts différents à Gdynia.',
    },
  ),
  Achievement(
    id: 'przewodnik',
    icon: '🏙️',
    name: {'pl': 'Przewodnik po mieście', 'en': 'City Guide', 'de': 'Stadtführer', 'fr': 'Guide de la ville'},
    description: {
      'pl': 'Zobaczyłeś wszystkie przystanki Gdyni.',
      'en': "You've seen every Gdynia stop.",
      'de': 'Du hast alle Haltestellen in Gdynia gesehen.',
      'fr': 'Vous avez vu tous les arrêts de Gdynia.',
    },
  ),
  Achievement(
    id: 'powrot-za-kierownice',
    icon: '⏸️',
    name: {'pl': 'Powrót za kierownicę', 'en': 'Back in the Seat', 'de': 'Zurück am Steuer', 'fr': 'De retour au volant'},
    description: {
      'pl': 'Skorzystałeś z opcji Kontynuuj.',
      'en': 'You used the Continue option.',
      'de': 'Du hast die Weiter-Option genutzt.',
      'fr': "Vous avez utilisé l'option Continuer.",
    },
  ),
  Achievement(
    id: 'tysiac-punktow',
    icon: '💯',
    name: {'pl': 'Tysiąc punktów', 'en': 'Thousand Points', 'de': 'Tausend Punkte', 'fr': 'Mille points'},
    description: {
      'pl': 'Zdobyłeś 1000 punktów w jednej jeździe.',
      'en': 'You scored 1000 points in a single run.',
      'de': 'Du hast 1000 Punkte in einer Fahrt erzielt.',
      'fr': 'Vous avez marqué 1000 points en une seule partie.',
    },
  ),
];
