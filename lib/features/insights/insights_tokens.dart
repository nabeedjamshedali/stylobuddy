import 'package:flutter/material.dart';

/// CSS values used only by the style insights screen (styles.css `.in-*`,
/// V18), `P/styles.css:437-439`.
abstract final class InsightsTokens {
  /// `insightPalette`, `P/app.js:325`.
  static const palette = [
    Color(0xFF0B8060),
    Color(0xFF67A68C),
    Color(0xFFA5C7AF),
    Color(0xFFD5E3D9),
    Color(0xFFE6CEB0),
    Color(0xFF9C9DA1),
    Color(0xFFC0CFC3),
    Color(0xFF718D7A),
  ];

  // .in-page
  static const pageInk = Color(0xFF19271E);

  // .in-kicker / .in-heading
  static const kicker = Color(0xFF087F62);
  static const headingSpan = Color(0xFF087F62);
  static const headingBody = Color(0xFF87948A);

  // .in-stats
  static const statBg = Color(0xFFF4F8F5);
  static const statBorder = Color(0xFFE3EEE6);
  static const statLabel = Color(0xFF758D7C);
  static const statValue = Color(0xFF0C6D51);
  static const statCaption = Color(0xFF87948A);

  // .in-section-head
  static const sectionCaption = Color(0xFF88968D);

  // .in-card
  static const cardBorder = Color(0xFFE4EBE6);

  // .in-donut / .in-legend
  static const donutValue = Color(0xFF1B2C21);
  static const donutLabel = Color(0xFF88978D);
  static const legendLabel = Color(0xFF607167);
  static const legendValue = Color(0xFF253B2E);

  // .in-bar-row
  static const barLabel = Color(0xFF576A5D);
  static const barCount = Color(0xFF263F30);
  static const barTrack = Color(0xFFEFF3EF);

  // .in-wear-summary / .in-progress
  static const wearValue = Color(0xFF0B7255);
  static const wearTotal = Color(0xFF91A095);
  static const wearCaption = Color(0xFF7F8C82);
  static const progressTrack = Color(0xFFEAF0EB);
  static const progressFill = Color(0xFF108362);
  static const note = Color(0xFF89958C);

  // .in-text-btn
  static const textButton = Color(0xFF08775A);

  // .in-garment
  static const garmentBorder = Color(0xFFE7EDE8);
  static const garmentThumbBg = Color(0xFFF4F5F2);
  static const garmentSubtitle = Color(0xFF8A968D);
  static const garmentChevron = Color(0xFF9CA9A0);

  // .in-occasions
  static const occasionValue = Color(0xFF0B7053);

  // .in-callout
  static const calloutBg = Color(0xFFEFF7F1);
  static const calloutBorder = Color(0xFFD9EADE);
  static const calloutIcon = Color(0xFF0B7959);
  static const calloutBody = Color(0xFF738579);
  static const calloutButtonBg = Color(0xFF087F62);

  // .in-empty
  static const emptyIcon = Color(0xFF0B8060);
  static const emptyBody = Color(0xFF89988B);
}
