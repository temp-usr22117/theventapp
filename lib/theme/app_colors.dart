import 'package:flutter/material.dart';

/// "Ember & Ash" palette: warm charcoal neutrals with a soft amber accent.
/// Use these tokens instead of hardcoded hex values.
class AppColors {
  AppColors._();

  // Surfaces (darkest → lightest)
  static const Color background = Color(0xFF161514);
  static const Color panel = Color(0xFF1B1918); // drawer, sidebar
  static const Color surface = Color(0xFF1F1D1B); // cards
  static const Color surfaceHover = Color(0xFF25221F);
  static const Color surfaceRaised = Color(0xFF282523); // inputs, menus, dialogs
  static const Color surfaceHigh = Color(0xFF34302D); // avatars, snackbars
  static const Color navBar = Color(0xEB1F1D1B); // translucent bottom nav

  // Lines
  static const Color border = Color(0xFF34302D);
  static const Color divider = Color(0xFF2A2725);

  // Text
  static const Color textPrimary = Color(0xFFF2EDE7);
  static const Color textBody = Color(0xFFE6E0D9); // vent content
  static const Color textSecondary = Color(0xFFB3ACA4);
  static const Color textMuted = Color(0xFF8F8880);
  static const Color textDisabled = Color(0xFF6B645E);

  // Accent
  static const Color accent = Color(0xFFE8A55A);
  static const Color accentLight = Color(0xFFF2BE82); // accent text on tints
  static const Color accentDark = Color(0xFFC98A43);
  static const Color onAccent = Color(0xFF1C1A18); // text/icons on accent fills

  // Semantic
  static const Color like = Color(0xFFE8798A);
  static const Color danger = Color(0xFFE2584A);
  static const Color error = Color(0xFFB5443A);
  static const Color success = Color(0xFF4E8A5E);
  static const Color shadow = Color(0xFF000000);
}
