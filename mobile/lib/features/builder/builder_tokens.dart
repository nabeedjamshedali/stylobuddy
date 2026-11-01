import 'package:flutter/material.dart';

/// CSS values used only by the Manual Outfit Builder screens (styles.css
/// `.mb-*` rules, V13).
abstract final class BuilderTokens {
  // Intro (.mb-intro)
  static const kicker = Color(0xFF087F62);
  static const introBody = Color(0xFF87918A);

  // Live/final preview (.mb-preview / .mb-final-preview)
  static const previewBorder = Color(0xFFE5ECE7);
  static const previewBg = Color(0xFFF8FAF7);
  static const previewCount = Color(0xFF87938B);
  static const previewButtonShadow = Color(0x33000000);
  static const emptyIcon = Color(0xFF087F62);
  static const emptyTitle = Color(0xFF374D3F);
  static const emptyBody = Color(0xFF74847B);

  // Selected tags (.mb-selected-tags)
  static const tagBorder = Color(0xFFD9E6DD);
  static const tagInk = Color(0xFF35634B);

  // Categories (.mb-categories)
  static const chipBorder = Color(0xFFE4EAE5);
  static const chipInk = Color(0xFF68786E);
  static const chipActiveBg = Color(0xFF0A7758);

  // Wardrobe grid (.mb-wardrobe-grid / .mb-item)
  static const itemBorder = Color(0xFFE6EBE6);
  static const itemSelectedBorder = Color(0xFF088365);
  static const itemSelectedBg = Color(0xFFF6FBF8);
  static const itemPhotoBg = Color(0xFFF6F7F5);
  static const itemCheckBorder = Color(0xFFD6E5DA);
  static const itemCheckInk = Color(0xFF087F62);
  static const itemSub = Color(0xFF86938A);

  // Summary rows (.mb-summary-row)
  static const summaryIconBg = Color(0xFFF6F7F5);
  static const summaryRowBorder = Color(0xFFE9EEE9);
  static const summarySub = Color(0xFF91A097);
  static const summaryChange = Color(0xFF087F62);

  // Form (.mb-form)
  static const fieldBorder = Color(0xFFDFE8E1);

  static const collectionCount = Color(0xFF87938B);
}
