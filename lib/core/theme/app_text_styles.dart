import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography tokens. The reference design uses a bold, tight, grotesque
/// sans-serif for headlines (Manrope reads closest to it) — never set
/// a TextStyle inline in a screen/widget.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get brandWordmark => GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 4,
        color: AppColors.textPrimary,
      );

  static TextStyle get headline => GoogleFonts.manrope(
        fontSize: 38,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineAccent => headline.copyWith(
        color: AppColors.accent,
      );

  static TextStyle get body => GoogleFonts.manrope(
        fontSize: 15,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get cardTitle => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get cardSubtitle => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  static TextStyle get button => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get caption => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );
}
