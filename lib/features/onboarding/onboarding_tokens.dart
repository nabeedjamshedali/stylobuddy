import 'package:flutter/material.dart';

/// CSS values used only by the onboarding screens (styles.css V4-V5, last
/// matching rule wins at a 390x844 viewport).
abstract final class OnboardingTokens {
  static const welcomeTitle = Color(0xFF0B755A);
  static const welcomeBody = Color(0xFF737C77);
  static const plainButton = Color(0xFF77817B);
  static const backButton = Color(0xFF7E8681);
  static const topInk = Color(0xFF717874);
  static const skipInk = Color(0xFF707672);
  static const headlineTitle = Color(0xFF191D1A);
  static const headlineBody = Color(0xFF8A918D);
  static const dot = Color(0xFFD2D7D4);
  static const dotActive = Color(0xFF0A8A68);
  static const primaryTop = Color(0xFF10A173);
  static const primaryBottom = Color(0xFF08845F);
  static const primaryShadow = Color(0x2406755A);
  static const occasionsBody = Color(0xFF909792);
  static const eventBorder = Color(0xFFDDE3DF);
  static const eventInk = Color(0xFF303734);
  static const eventGlyph = Color(0xFF1B2A23);
  static const eventChosenBorder = Color(0xFF087E60);
  static const eventChosenBg = Color(0xFFF4FBF7);
  static const eventChosenInk = Color(0xFF06593E);
  static const choiceDotBorder = Color(0xFFDCE2DE);
  static const choiceDotRing = Color(0xFFD8EFE3);

  // F24 `/gender` (prototype v26 `.v26-copy`, `.v26-gender-card`, `.v26-radio`).
  static const genderAccent = Color(0xFF087F62);
  static const genderTitle = Color(0xFF191D1A);
  static const genderBody = Color(0xFF77847F);
  static const genderOverline = Color(0xFF717874);
  static const genderCardBorder = Color(0xFFE0E8E3);
  static const genderCardBg = Color(0xFFFAFCFB);
  static const genderCardChosenBg = Color(0xFFF2FBF6);
  static const genderCardSub = Color(0xFF6E7D74);
  static const genderRadioBorder = Color(0xFFA0B4A9);
}
