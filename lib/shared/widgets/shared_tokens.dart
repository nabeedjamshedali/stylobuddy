import 'package:flutter/material.dart';

/// CSS values used only by the shared prototype widgets (styles.css base +
/// v2/V22 overrides).
abstract final class SharedTokens {
  static const navBorder = Color(0xFFECF0EC);
  static const navInactive = Color(0xFF89958E);
  static const headButtonBg = Color(0xFFF5F7F5);
  static const headButtonInk = Color(0xFF334439);
  static const secondaryBorder = Color(0xFFCDE3D7);
  static const dangerInk = Color(0xFFC95858);
  static const dangerBorder = Color(0xFFF0D4D4);
  static const chipBorder = Color(0xFFE8ECE8);
  static const chipInk = Color(0xFF6A766F);
  static const fieldBorder = Color(0xFFE4E9E5);
  static const optionRadioBorder = Color(0xFFC6D3C9);
  static const optionSelectedBg = Color(0xFFF4FAF6);
  static const optionDescription = Color(0xFF85928B);
  static const tileBorder = Color(0xFFF0F1EE);
  static const tileSelectedBg = Color(0xFFEDF7F1);
  static const tileSub = Color(0xFF8B9B91);
  static const tileLock = Color(0xFF213C32);
  static const toastBg = Color(0xFF172A20);
  static const toastShadow = Color(0x33000000);
  static const modalBackdrop = Color(0x7810271C);
  static const modalClose = Color(0xFFF3F5F3);
  static const spinnerTrack = Color(0xFFDBECE1);
  static const progressTrack = Color(0xFFE8EEE9);
  static const brandInk = Color(0xFF101411);
  static const demoNote = Color(0xFFA0A9A2);
  static const aiNote = Color(0xFF97A099);
  static const introNote = Color(0xFFA1ACA3);
  static const shareNote = Color(0xFFA0AAA2);

  /// Prototype `hangerLogo` (P/app.js:295).
  static const hangerSvg =
      '<svg viewBox="0 0 72 69" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M36 17.8c0-6.2 9.3-7.5 11.3-1.4 1.1 3.4-.3 6.5-4 8.7l-7.3 5.2v6.6'
      'L10.3 56c-4.2 3.2-2 9.8 3.3 9.8h44.8c5.3 0 7.5-6.6 3.3-9.8L36 36.9" '
      'stroke="#08654B" stroke-width="5.2" stroke-linecap="round" '
      'stroke-linejoin="round"/></svg>';
}
