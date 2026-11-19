import 'package:flutter/material.dart';

/// Mood / emotion a user can tag a vent with.
///
/// [key] is the value persisted in Firestore under the post's `mood` field,
/// so never rename an existing key — add a new value instead.
enum Mood {
  frustrated(
    'frustrated',
    'Frustrated',
    Icons.sentiment_very_dissatisfied_rounded,
    Color(0xFFFF8A3D),
  ),
  sad(
    'sad',
    'Sad',
    Icons.sentiment_dissatisfied_rounded,
    Color(0xFF4FA3FF),
  ),
  anxious(
    'anxious',
    'Anxious',
    Icons.psychology_alt_rounded,
    Color(0xFFFFC94D),
  ),
  angry(
    'angry',
    'Angry',
    Icons.local_fire_department_rounded,
    Color(0xFFFF4D4D),
  ),
  lonely(
    'lonely',
    'Lonely',
    Icons.person_outline_rounded,
    Color(0xFF9E7BFF),
  ),
  overwhelmed(
    'overwhelmed',
    'Overwhelmed',
    Icons.waves_rounded,
    Color(0xFF26C6DA),
  ),
  tired(
    'tired',
    'Tired',
    Icons.bedtime_rounded,
    Color(0xFF90A4AE),
  ),
  confused(
    'confused',
    'Confused',
    Icons.help_outline_rounded,
    Color(0xFFF06292),
  ),
  hopeful(
    'hopeful',
    'Hopeful',
    Icons.wb_sunny_rounded,
    Color(0xFF66BB6A),
  );

  const Mood(this.key, this.label, this.icon, this.color);

  final String key;
  final String label;
  final IconData icon;
  final Color color;

  /// Parses a stored mood key. Returns null for missing or unknown values
  /// (e.g. vents created before moods existed).
  static Mood? fromKey(Object? key) {
    if (key is! String) return null;
    for (final mood in Mood.values) {
      if (mood.key == key) return mood;
    }
    return null;
  }
}
