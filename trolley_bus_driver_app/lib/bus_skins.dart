import 'package:flutter/material.dart';

/// A cosmetic trolleybus livery - purely visual, no gameplay effect.
/// Unlocked by earning the tied achievement (see achievements.dart) rather
/// than tracking its own unlock set, so a skin becomes available the
/// instant its achievement fires with zero extra persistence.
class BusSkin {
  final String id;
  final Map<String, String> name;
  final Color body;
  final Color stripe;

  /// Achievement id required to unlock this skin, or null if available
  /// from the very first run.
  final String? requiresAchievement;

  const BusSkin({
    required this.id,
    required this.name,
    required this.body,
    required this.stripe,
    this.requiresAchievement,
  });

  String nameFor(String lang) => name[lang] ?? name['pl']!;
}

const kClassicBusSkin = BusSkin(
  id: 'classic',
  name: {'pl': 'Klasyczny', 'en': 'Classic', 'de': 'Klassisch', 'fr': 'Classique'},
  body: Color(0xFF2C6FE0),
  stripe: Color(0xFFFFE14D),
);

/// Ids intentionally reuse achievement ids from achievements.dart so a
/// skin unlocks the moment its matching badge does.
const List<BusSkin> kBusSkins = [
  kClassicBusSkin,
  BusSkin(
    id: 'eco',
    name: {'pl': 'Ekologiczny', 'en': 'Eco', 'de': 'Öko', 'fr': 'Écolo'},
    body: Color(0xFF1FA463),
    stripe: Color(0xFFC6FF4D),
    requiresAchievement: 'odkrywca',
  ),
  BusSkin(
    id: 'zloty',
    name: {'pl': 'Złoty', 'en': 'Golden', 'de': 'Goldener', 'fr': 'Doré'},
    body: Color(0xFFD4A017),
    stripe: Color(0xFFFF8A2B),
    requiresAchievement: 'maratonczyk',
  ),
  BusSkin(
    id: 'neon',
    name: {'pl': 'Neonowy', 'en': 'Neon', 'de': 'Neon', 'fr': 'Néon'},
    body: Color(0xFFFF4DE3),
    stripe: Color(0xFF4DEAFF),
    requiresAchievement: 'idealna-jazda',
  ),
  BusSkin(
    id: 'legenda',
    name: {'pl': 'Legendarny', 'en': 'Legendary', 'de': 'Legendär', 'fr': 'Légendaire'},
    body: Color(0xFF17161D),
    stripe: Color(0xFF4DEAFF),
    requiresAchievement: 'legenda',
  ),
];
