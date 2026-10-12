import 'package:flutter/material.dart';

/// Design tokens extracted from the reference shot (dark, warm-gradient
/// fashion-app UI). Keep all raw colors here — never inline a hex value
/// in a widget.
class AppColors {
  AppColors._();

  // Base surfaces
  static const Color background = Color(0xFF0E0C0B);
  static const Color surface = Color(0xFF17140F);
  static const Color surfaceMuted = Color(0xFF1F1B16);

  // Brand gradient (warm amber -> coral -> deep brown), the signature
  // "glow" backdrop used behind every onboarding screen.
  static const List<Color> heroGradient = [
    Color(0xFFFF7A3D), // bright coral-orange glow
    Color(0xFFB2522A), // warm amber-brown
    Color(0xFF241B16), // fades to near-black
    Color(0xFF0E0C0B),
  ];

  // Accent used for CTAs, highlighted word in headline, active dot, price.
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentDeep = Color(0xFFE8552A);

  static const List<Color> accentButtonGradient = [
    Color(0xFFFF8A4C),
    Color(0xFFFF5B2E),
  ];

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC9C2BB);
  static const Color textMuted = Color(0xFF8A8277);

  // Chrome
  static const Color glassFill = Color(0x33FFFFFF);
  static const Color glassBorder = Color(0x1FFFFFFF);
  static const Color dotInactive = Color(0x40FFFFFF);
}
