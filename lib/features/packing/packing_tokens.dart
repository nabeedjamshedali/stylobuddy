import 'package:flutter/material.dart';

/// CSS values used only by the packing assistant screens (styles.css `.pk-*`,
/// V16).
abstract final class PackingTokens {
  // Heading (.pk-eyebrow / .pk-sub)
  static const eyebrow = Color(0xFF087F62);
  static const subtitle = Color(0xFF89948D);

  // Feature card (.pk-feature)
  static const featureBg = Color(0xFFEFF6F0);
  static const featureBorder = Color(0xFFE1EEE4);
  static const featureIconBg = Color(0xFFD6E8D9);
  static const featureIconInk = Color(0xFF087F62);
  static const featureBody = Color(0xFF748277);

  // Section title (.pk-section-title)
  static const sectionCount = Color(0xFF91A097);

  // Empty state (.pk-empty)
  static const emptyBorder = Color(0xFFDCE8DF);
  static const emptyBg = Color(0xFFFAFCFB);
  static const emptyIcon = Color(0xFF087F62);
  static const emptyBody = Color(0xFF85948B);

  // Primary button (.pk-button)
  static const buttonBg = Color(0xFF087F62);

  // Trip card (.pk-trip)
  static const tripBorder = Color(0xFFE6ECE8);
  static const tripIconBg = Color(0xFFEEF6F0);
  static const tripIconInk = Color(0xFF087F62);
  static const tripMeta = Color(0xFF88948D);
  static const progressTrack = Color(0xFFE9EEE9);
  static const progressFill = Color(0xFF087F62);
  static const chevron = Color(0xFF9AA79F);

  // Form (.pk-form)
  static const formBorder = Color(0xFFDFE7E2);
  static const formInk = Color(0xFF24352B);

  // Trip info / items preview (.pk-info / .pk-items-preview)
  static const infoBorder = Color(0xFFE2EAE4);
  static const infoSub = Color(0xFF8A968E);
  static const previewBg = Color(0xFFF8F9F7);

  // Checklist header / toolbar (.pk-count / .pk-toolbar)
  static const countBg = Color(0xFFEFF6F0);
  static const countInk = Color(0xFF087F62);
  static const toolbarBorder = Color(0xFFDCE7DF);
  static const toolbarInk = Color(0xFF286749);

  // Checklist rows (.pk-checklist / .pk-check)
  static const checkBorder = Color(0xFFE4EAE5);
  static const checkAccent = Color(0xFF087F62);
  static const thumbBg = Color(0xFFF6F8F6);
  static const doneInk = Color(0xFF9AA59D);
  static const removeGlyph = Color(0xFFA5AEA7);

  // Secondary / danger actions (.pk-secondary / .pk-delete)
  static const secondaryBorder = Color(0xFFD6E5DC);
  static const secondaryInk = Color(0xFF087F62);
  static const deleteInk = Color(0xFFAA6969);

  // Add-items grid (.pk-add-grid / .pk-add-card)
  static const addCardBorder = Color(0xFFE5EBE6);
  static const addCardEm = Color(0xFF087F62);
}
