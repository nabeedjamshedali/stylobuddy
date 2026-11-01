import 'package:flutter/material.dart';

/// CSS values used only by the calendar planner screens (styles.css `.cp-*`,
/// V15).
abstract final class CalendarTokens {
  // Heading / month bar (.cp-eyebrow / .cp-subtitle / .cp-month)
  static const eyebrow = Color(0xFF09815E);
  static const subtitle = Color(0xFF88968D);
  static const monthBorder = Color(0xFFE7EDE8);
  static const monthLabel = Color(0xFF90A099);
  static const monthControlBorder = Color(0xFFE2E9E4);

  // Calendar grid (.cp-calendar / .cp-days)
  static const dayName = Color(0xFF8F9D94);
  static const dayInk = Color(0xFF4E6257);
  static const dayActiveBg = Color(0xFF087E60);
  static const dayMarker = Color(0xFF099168);

  // Summary (.cp-summary)
  static const summaryMuted = Color(0xFF87978C);
  static const summaryStrong = Color(0xFF0B7858);

  // Selected head (.cp-selected-head)
  static const removeInk = Color(0xFFAD6262);

  // Plan card (.cp-plan-card)
  static const planCardBorder = Color(0xFFE5EBE5);
  static const planImageBg = Color(0xFFF6F7F3);
  static const planLabel = Color(0xFF0D7E60);
  static const planSub = Color(0xFF91A096);
  static const planLink = Color(0xFF087E60);

  // Empty state (.cp-empty)
  static const emptyBorder = Color(0xFFDCE8DF);
  static const emptyBg = Color(0xFFFBFDFA);
  static const emptyIcon = Color(0xFF087E60);
  static const emptyBody = Color(0xFF95A199);

  // Primary / secondary actions (.cp-primary / .cp-secondary-actions)
  static const primaryBg = Color(0xFF087E60);
  static const secondaryInk = Color(0xFF197859);

  // Chooser list (.cp-outfit-list / .cp-thumbnail)
  static const outfitRowBorder = Color(0xFFE7EDE8);
  static const thumbnailBg = Color(0xFFF5F6F3);
  static const outfitName = Color(0xFF8D9B92);
  static const outfitChevron = Color(0xFF8FA297);

  // Alt buttons (.cp-alt)
  static const altBorder = Color(0xFFE1EBE3);
  static const altBg = Color(0xFFF9FCFA);
  static const altInk = Color(0xFF0B7959);

  // Form (.cp-form)
  static const formLabel = Color(0xFF5A7161);
  static const formBorder = Color(0xFFDDE7DF);
  static const formInk = Color(0xFF23362B);
}
