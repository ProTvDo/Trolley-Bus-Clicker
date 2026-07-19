# Złap Prąd! (Flutter)

Gra zręcznościowa o trolejbusie — port natywny (Android + iOS) gry
`zlap-prad.html` z tego repo, napisany we Flutterze/Dart, tak żeby dało się
ją opublikować w Google Play i App Store.

## Uruchomienie lokalnie

```bash
flutter pub get
flutter run            # na podłączonym urządzeniu/emulatorze
flutter run -d chrome   # podgląd w przeglądarce
```

## Build na Android (Google Play)

Wymaga zainstalowanego Android Studio / Android SDK (`flutter doctor` musi
pokazywać zielony ptaszek przy "Android toolchain").

1. Wygeneruj klucz do podpisywania (jeśli jeszcze go nie masz):
   ```bash
   keytool -genkey -v -keystore ~/zlap-prad-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Utwórz `android/key.properties` (NIE commituj go do repo):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/absolutna/sciezka/do/zlap-prad-upload.jks
   ```
3. Zbuduj paczkę pod Google Play (Android App Bundle):
   ```bash
   flutter build appbundle --release
   ```
   Plik wynikowy: `build/app/outputs/bundle/release/app-release.aab` — to
   właśnie ten plik wgrywa się do Google Play Console.

## Build na iOS (App Store)

Wymaga macOS + Xcode + konta Apple Developer.

```bash
flutter build ipa --release
```

Plik wynikowy w `build/ios/ipa/` — wgrywany przez Xcode Organizer albo
Transporter do App Store Connect.

## Struktura

- `lib/game_controller.dart` — stan i logika gry (pasy, przewód trakcyjny,
  przeszkody, życia, mnożnik wyniku, reconnect po zerwaniu kontaktu).
- `lib/game_painter.dart` — rysowanie sceny na `Canvas` (droga, wire, bus,
  cząsteczki iskier).
- `lib/game_screen.dart` — ekran gry, HUD, nakładki (start/game over/reconnect).
- `lib/audio.dart` — proceduralne dźwięki (bez plików audio, syntezowane w
  locie, tak jak w oryginalnej wersji webowej).
- `lib/models.dart` — modele danych (segmenty trasy, przeszkody, iskry, gwiazdy).

Najlepszy wynik zapisywany jest lokalnie przez `shared_preferences`.
