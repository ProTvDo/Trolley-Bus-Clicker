/// Gdyńskie akcenty w grze: nazwy przystanków i krótkie ciekawostki o mieście,
/// pokazywane na tabliczce przy mijaniu przystanku.
///
/// UWAGA DLA EDYTUJĄCEGO: to jedyne miejsce, w którym trzymamy te treści -
/// żeby dało się je łatwo poprawić bez ruszania logiki gry. Nazwy przystanków
/// i fakty warto zweryfikować z aktualnym rozkładem ZKM Gdynia oraz materiałami
/// miasta, zanim gra trafi do szerszej dystrybucji lub prezentacji dla Gdyni.
library;

class GdyniaStop {
  const GdyniaStop({required this.name, required this.story});

  /// Nazwa przystanku - nazwa własna, ta sama we wszystkich językach.
  final String name;

  /// Krótka ciekawostka, kluczowana kodem języka ('pl', 'en', 'de', 'fr').
  /// Brakujący język spada na polski (patrz [storyFor]).
  final Map<String, String> story;

  String storyFor(String languageCode) => story[languageCode] ?? story['pl']!;
}

const List<GdyniaStop> kGdyniaStops = [
  GdyniaStop(
    name: 'Skwer Kościuszki',
    story: {
      'pl': 'Reprezentacyjny deptak Gdyni prowadzący prosto do morza. Przy pobliskim nabrzeżu cumują żaglowiec Dar Pomorza i niszczyciel ORP Błyskawica.',
      'en': 'Gdynia\'s main promenade, leading straight to the sea. The tall ship Dar Pomorza and the destroyer ORP Błyskawica are moored at the nearby quay.',
      'de': 'Die Hauptpromenade von Gdynia, die direkt zum Meer führt. Am nahen Kai liegen das Segelschiff Dar Pomorza und der Zerstörer ORP Błyskawica.',
      'fr': 'La principale promenade de Gdynia, menant droit à la mer. Le voilier Dar Pomorza et le destroyer ORP Błyskawica sont amarrés au quai voisin.',
    },
  ),
  GdyniaStop(
    name: 'Plac Kaszubski',
    story: {
      'pl': 'Jeden z najstarszych placów miasta, pamiątka po kaszubskiej wsi rybackiej, z której wyrosła Gdynia.',
      'en': 'One of the city\'s oldest squares - a reminder of the Kashubian fishing village that Gdynia grew from.',
      'de': 'Einer der ältesten Plätze der Stadt - eine Erinnerung an das kaschubische Fischerdorf, aus dem Gdynia entstand.',
      'fr': 'L\'une des plus anciennes places de la ville, souvenir du village de pêcheurs cachoube dont est née Gdynia.',
    },
  ),
  GdyniaStop(
    name: 'Gdynia Główna',
    story: {
      'pl': 'Główny dworzec kolejowy miasta i węzeł przesiadkowy - stąd odjeżdżają pociągi w całą Polskę.',
      'en': 'The city\'s main railway station and transfer hub - trains leave from here across all of Poland.',
      'de': 'Der Hauptbahnhof der Stadt und Umsteigeknoten - von hier fahren Züge in ganz Polen.',
      'fr': 'La gare principale de la ville et pôle de correspondance - les trains partent d\'ici dans toute la Pologne.',
    },
  ),
  GdyniaStop(
    name: 'Hala Targowa',
    story: {
      'pl': 'Zabytkowe hale targowe z okresu międzywojennego - do dziś tętnią życiem i handlem.',
      'en': 'Historic interwar market halls - still bustling with trade and life today.',
      'de': 'Historische Markthallen aus der Zwischenkriegszeit - bis heute voller Leben und Handel.',
      'fr': 'Halles de marché historiques de l\'entre-deux-guerres - toujours animées par le commerce.',
    },
  ),
  GdyniaStop(
    name: 'Wzgórze Św. Maksymiliana',
    story: {
      'pl': 'Dzielnica na wzniesieniu nad centrum, z widokiem na port i zatokę.',
      'en': 'A district on the hillside above the centre, overlooking the port and the bay.',
      'de': 'Ein Stadtteil auf der Anhöhe über dem Zentrum mit Blick auf Hafen und Bucht.',
      'fr': 'Un quartier sur la colline au-dessus du centre, dominant le port et la baie.',
    },
  ),
  GdyniaStop(
    name: 'Kamienna Góra',
    story: {
      'pl': 'Wzgórze z tarasem widokowym na całą Gdynię i zatokę. Na szczyt można wjechać zabytkowym wyciągiem.',
      'en': 'A hill with a viewing terrace over all of Gdynia and the bay. A historic funicular takes you to the top.',
      'de': 'Ein Hügel mit Aussichtsterrasse über ganz Gdynia und die Bucht. Eine historische Standseilbahn fährt hinauf.',
      'fr': 'Une colline avec terrasse panoramique sur toute Gdynia et la baie. Un funiculaire historique mène au sommet.',
    },
  ),
  GdyniaStop(
    name: 'Redłowo',
    story: {
      'pl': 'Dzielnica z rezerwatem przyrody Kępa Redłowska i klifem opadającym wprost do morza.',
      'en': 'A district with the Kępa Redłowska nature reserve and a cliff dropping straight into the sea.',
      'de': 'Ein Stadtteil mit dem Naturschutzgebiet Kępa Redłowska und einer Steilküste direkt am Meer.',
      'fr': 'Un quartier avec la réserve naturelle de Kępa Redłowska et une falaise plongeant dans la mer.',
    },
  ),
  GdyniaStop(
    name: 'Orłowo',
    story: {
      'pl': 'Nadmorska dzielnica z drewnianym molo i słynnym klifem orłowskim.',
      'en': 'A seaside district with a wooden pier and the famous Orłowo cliff.',
      'de': 'Ein Stadtteil am Meer mit hölzerner Seebrücke und dem berühmten Kliff von Orłowo.',
      'fr': 'Un quartier balnéaire avec une jetée en bois et la célèbre falaise d\'Orłowo.',
    },
  ),
  GdyniaStop(
    name: 'Witomino',
    story: {
      'pl': 'Dzielnica mieszkaniowa na wzgórzach, otoczona lasami Trójmiejskiego Parku Krajobrazowego.',
      'en': 'A residential district on the hills, surrounded by the forests of the Tricity Landscape Park.',
      'de': 'Ein Wohnviertel auf den Hügeln, umgeben von den Wäldern des Dreistadt-Landschaftsparks.',
      'fr': 'Un quartier résidentiel sur les collines, entouré des forêts du parc paysager de la Tricité.',
    },
  ),
  GdyniaStop(
    name: 'Karwiny',
    story: {
      'pl': 'Jedna z młodszych dzielnic Gdyni, zbudowana głównie w latach 70. i 80.',
      'en': 'One of Gdynia\'s younger districts, built mainly in the 1970s and 1980s.',
      'de': 'Einer der jüngeren Stadtteile Gdynias, überwiegend in den 1970er und 1980er Jahren erbaut.',
      'fr': 'L\'un des quartiers les plus récents de Gdynia, bâti surtout dans les années 1970 et 1980.',
    },
  ),
  GdyniaStop(
    name: 'Dąbrowa',
    story: {
      'pl': 'Rozległa dzielnica na zachodzie miasta, sąsiadująca z lasami i jeziorem.',
      'en': 'A sprawling district in the west of the city, neighbouring forests and a lake.',
      'de': 'Ein weitläufiger Stadtteil im Westen der Stadt, an Wälder und einen See grenzend.',
      'fr': 'Un vaste quartier à l\'ouest de la ville, voisin des forêts et d\'un lac.',
    },
  ),
  GdyniaStop(
    name: 'Chylonia',
    story: {
      'pl': 'Jedna z najstarszych osad na terenie dzisiejszej Gdyni, wzmiankowana na długo przed powstaniem miasta.',
      'en': 'One of the oldest settlements in what is now Gdynia, recorded long before the city itself existed.',
      'de': 'Eine der ältesten Siedlungen im heutigen Gdynia, lange vor der Stadtgründung erwähnt.',
      'fr': 'L\'un des plus anciens villages de l\'actuelle Gdynia, mentionné bien avant la naissance de la ville.',
    },
  ),
  GdyniaStop(
    name: 'Grabówek',
    story: {
      'pl': 'Dzielnica tuż przy śródmieściu, jeden z ważnych węzłów gdyńskiej sieci trolejbusowej.',
      'en': 'A district right next to the centre and one of the key junctions of Gdynia\'s trolleybus network.',
      'de': 'Ein Stadtteil direkt am Zentrum und einer der wichtigen Knotenpunkte des Obusnetzes von Gdynia.',
      'fr': 'Un quartier tout près du centre et l\'un des nœuds importants du réseau de trolleybus de Gdynia.',
    },
  ),
  GdyniaStop(
    name: 'Oksywie',
    story: {
      'pl': 'Najstarsza część Gdyni, z zabytkowym kościołem na wzgórzu nad morzem.',
      'en': 'The oldest part of Gdynia, with a historic church on the hill above the sea.',
      'de': 'Der älteste Teil Gdynias, mit einer historischen Kirche auf dem Hügel über dem Meer.',
      'fr': 'La partie la plus ancienne de Gdynia, avec une église historique sur la colline au-dessus de la mer.',
    },
  ),
  GdyniaStop(
    name: 'Obłuże',
    story: {
      'pl': 'Dzielnica w północnej części miasta, historycznie związana z pobliskim portem wojennym.',
      'en': 'A district in the north of the city, historically tied to the nearby naval port.',
      'de': 'Ein Stadtteil im Norden der Stadt, historisch mit dem nahen Marinehafen verbunden.',
      'fr': 'Un quartier au nord de la ville, historiquement lié au port militaire voisin.',
    },
  ),
  GdyniaStop(
    name: 'Cisowa',
    story: {
      'pl': 'Zachodni kraniec Gdyni - dawna wieś, dziś dzielnica z własnym przystankiem kolejowym.',
      'en': 'Gdynia\'s western edge - a former village, today a district with its own railway stop.',
      'de': 'Der westliche Rand Gdynias - ein ehemaliges Dorf, heute ein Stadtteil mit eigenem Bahnhaltepunkt.',
      'fr': 'L\'extrémité ouest de Gdynia - ancien village, aujourd\'hui quartier avec sa propre halte ferroviaire.',
    },
  ),
  GdyniaStop(
    name: 'Stocznia',
    story: {
      'pl': 'Tereny stoczniowe i portowe - serce gospodarcze Gdyni od czasów budowy portu.',
      'en': 'The shipyard and port area - Gdynia\'s economic heart ever since the port was built.',
      'de': 'Werft- und Hafengelände - das wirtschaftliche Herz Gdynias seit dem Bau des Hafens.',
      'fr': 'La zone du chantier naval et du port - le cœur économique de Gdynia depuis sa construction.',
    },
  ),
  GdyniaStop(
    name: 'Leszczynki',
    story: {
      'pl': 'Dzielnica przy trasie na północ miasta, z zabudową z czasów międzywojennego boomu budowlanego.',
      'en': 'A district on the route north, with buildings from the interwar construction boom.',
      'de': 'Ein Stadtteil an der Route nach Norden, mit Bauten aus dem Bauboom der Zwischenkriegszeit.',
      'fr': 'Un quartier sur la route vers le nord, avec des bâtiments du boom immobilier de l\'entre-deux-guerres.',
    },
  ),
];
