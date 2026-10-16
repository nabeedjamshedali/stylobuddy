import 'package:flutter/material.dart';

/// CSS values used only by the profile/settings/premium screens
/// (styles.css `.pf-*`, V19), `P/styles.css:440-442`.
abstract final class ProfileTokens {
  // .pf-kicker / .pf-section-title
  static const kicker = Color(0xFF0A8563);
  static const sectionTitle = Color(0xFF778D80);

  // .pf-identity
  static const avatarBg = Color(0xFFE3F0E7);
  static const avatarInk = Color(0xFF087656);
  static const identitySubtitle = Color(0xFF87958A);
  static const editIconBorder = Color(0xFFE1E8E1);
  static const editIconInk = Color(0xFF087B59);

  // .pf-premium
  static const premiumGradientStart = Color(0xFF086E52);
  static const premiumGradientEnd = Color(0xFF0C9370);
  static const premiumStarBorder = Color(0x55FFFFFF);
  static const premiumKicker = Color(0xFFD8F7E7);
  static const premiumEm = Color(0xFFE6FAF0);

  // .pf-menu / .pf-settings-card
  static const cardBorder = Color(0xFFE6EBE7);
  static const rowDivider = Color(0xFFF0F2EF);
  static const menuIconBg = Color(0xFFF0F7F2);
  static const menuIconInk = Color(0xFF08775A);
  static const menuRowInk = Color(0xFF1C2B22);
  static const menuSubtitle = Color(0xFF88988D);
  static const chevron = Color(0xFF9CAAA0);

  // .pf-form-intro / .pf-form
  static const introBody = Color(0xFF819087);
  static const formInk = Color(0xFF243329);
  static const formBorder = Color(0xFFDCE5DD);
  static const formFocusBorder = Color(0xFF108965);

  // .pf-helper
  static const helper = Color(0xFF8A978D);

  // .pf-choice / .pf-plan-choice
  static const choiceBorder = Color(0xFFE3E9E3);
  static const choiceInk = Color(0xFF34443A);
  static const choiceMarker = Color(0xFF91A99A);
  static const choiceSelectedBg = Color(0xFFF1FAF4);
  static const choiceSelectedBorder = Color(0xFF15936C);
  static const choiceSelectedInk = Color(0xFF096B50);
  static const choiceSelectedMarker = Color(0xFF08775A);

  // .pf-toggle-row
  static const toggleAccent = Color(0xFF087E60);

  // .pf-version
  static const version = Color(0xFFA4AEA7);

  // .pf-empty
  static const emptyIcon = Color(0xFF087D5C);
  static const emptyBody = Color(0xFF849488);

  // .pf-warning
  static const warningBorder = Color(0xFFF3DFC2);
  static const warningBg = Color(0xFFFFFAF1);
  static const warningInk = Color(0xFF8F7350);

  // .pf-paywall
  static const paywallGradientStart = Color(0xFF073E31);
  static const paywallGradientEnd = Color(0xFF0A8260);
  static const paywallKicker = Color(0xFFC8E9DA);
  static const paywallBody = Color(0xFFD8EEE4);

  // .pf-benefits
  static const benefitBorder = Color(0xFFE4EBE5);
  static const benefitDivider = Color(0xFFEDF1ED);
  static const benefitMark = Color(0xFF087F62);

  // .pf-plan-choice
  static const planSubtitle = Color(0xFF8C998F);

  // .pf-current-plan
  static const currentPlanBorder = Color(0xFFD7E7DB);
  static const currentPlanBg = Color(0xFFF2F9F4);
  static const currentPlanLabel = Color(0xFF728C79);
  static const currentPlanBody = Color(0xFF75897A);
  static const currentPlanLink = Color(0xFF087C59);
}
