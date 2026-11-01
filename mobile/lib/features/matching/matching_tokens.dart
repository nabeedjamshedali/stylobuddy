import 'package:flutter/material.dart';

/// CSS values used only by the Match My Clothes screens (styles.css V11
/// `.mm-*` rules).
abstract final class MatchingTokens {
  // Intro (.mm-intro / .mm-steps)
  static const kicker = Color(0xFF087F62);
  static const stepsBorder = Color(0xFFE9EDE9);
  static const stepsDivider = Color(0xFFEDF0ED);
  static const stepNumber = Color(0xFF0C8B65);
  static const stepCaption = Color(0xFF89958D);

  // Step heading (.mm-heading)
  static const headingInk = Color(0xFF191D1A);

  // Select (.mm-selection-summary / .mm-selection-strip / .mm-chips)
  static const summaryBg = Color(0xFFF0F7F2);
  static const summarySub = Color(0xFF627A6B);
  static const miniBg = Color(0xFFF6F7F4);
  static const miniBorder = Color(0xFFE6ECE7);
  static const miniLock = Color(0xFF07825D);
  static const chipBorder = Color(0xFFE3E9E3);
  static const chipInk = Color(0xFF69786E);

  // Item tiles (.mm-item / .mm-image / .mm-check / .mm-lock-symbol)
  static const itemBorder = Color(0xFFE6EBE6);
  static const itemInk = Color(0xFF16231C);
  static const itemSub = Color(0xFF8A968D);
  static const imageBg = Color(0xFFF7F8F6);
  static const markBorder = Color(0xFFD6E1D9);
  static const markOn = Color(0xFF087F62);

  // Lock legend (.mm-lock-legend / .mm-dot)
  static const legendInk = Color(0xFF748379);
  static const dotBorder = Color(0xFF8BA79B);

  // Note / warning (.mm-note / .notice.warning)
  static const noteBg = Color(0xFFF2F8F4);
  static const noteBorder = Color(0xFFDFEBE3);
  static const warningBg = Color(0xFFFFF6E8);
  static const warningInk = Color(0xFF89653D);

  // Preferences (.mm-preference-card / .mm-toggle)
  static const cardBorder = Color(0xFFE8EEE9);
  static const toggleCaption = Color(0xFF627A6B);
}
