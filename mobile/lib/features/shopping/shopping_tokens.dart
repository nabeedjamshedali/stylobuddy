import 'package:flutter/material.dart';

/// CSS values used only by the shopping assistant screens (styles.css
/// `.sh-*`, V17), `P/styles.css:433-436`.
abstract final class ShoppingTokens {
  // Intro (.sh-intro)
  static const introBg = Color(0xFFF1F6F1);
  static const introBorder = Color(0xFFE6EEE7);
  static const eyebrow = Color(0xFF0B7758);
  static const introHeading = Color(0xFF173E30);
  static const introBody = Color(0xFF65776B);

  // Tabs (.sh-tabs)
  static const tabsBg = Color(0xFFF2F5F2);
  static const tabInactive = Color(0xFF718178);
  static const tabActiveBg = Colors.white;
  static const tabActiveInk = Color(0xFF08644A);
  static const tabCount = Color(0xFF718178);

  // Section head (.sh-section-head)
  static const sectionCount = Color(0xFF91A096);
  static const introNote = Color(0xFF84928A);

  // Suggestion card (.sh-suggestion / .sh-art)
  static const suggestionBorder = Color(0xFFE6EBE6);
  static const artSymbol = Color(0xFF507260);
  static const artCaption = Color(0xFF9EAAA0);
  static const kicker = Color(0xFF087E5E);
  static const cardTone = Color(0xFF829087);
  static const cardLink = Color(0xFF087E60);

  // Art tile backgrounds, by catalog id (.sh-<id>)
  static const artBg = {
    'neutral-blazer': [Color(0xFFECE7DE), Color(0xFFF6F4EF)],
    'versatile-knit': [Color(0xFFE2E7E0), Color(0xFFF4F5F1)],
    'formal-shoes': [Color(0xFFE6E3DC), Color(0xFFF2F1EB)],
    'everyday-bag': [Color(0xFFE7E0D8), Color(0xFFF7F4EF)],
    'neutral-bottom': [Color(0xFFE1E5E6), Color(0xFFF2F4F3)],
  };

  // Phase block (.sh-phase)
  static const phaseBorder = Color(0xFFE3EAE4);
  static const phaseBg = Color(0xFFFAFBF9);
  static const phaseLabel = Color(0xFF178265);
  static const phaseBody = Color(0xFF7E8B82);
  static const phaseDivider = Color(0xFFE5EBE6);

  // Empty state (.sh-empty)
  static const emptyBg = Color(0xFFF8FAF8);
  static const emptyBorder = Color(0xFFD9E2DB);
  static const emptyInk = Color(0xFF0D6650);
  static const emptyBody = Color(0xFF89968C);

  // Detail (.sh-detail / .sh-block / .sh-owned / .sh-tip)
  static const detailTone = Color(0xFF777F79);
  static const detailMuted = Color(0xFF7D8980);
  static const ownedBorder = Color(0xFFE8EEE8);
  static const ownedBg = Color(0xFFFAFBF9);
  static const ownedName = Color(0xFF5D6C61);
  static const tipBg = Color(0xFFF3F8F4);
  static const tipIcon = Color(0xFF078362);
  static const tipBody = Color(0xFF536B5B);
}
