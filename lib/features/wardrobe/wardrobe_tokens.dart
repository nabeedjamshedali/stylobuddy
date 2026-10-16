import 'package:flutter/material.dart';

/// CSS values used only by the wardrobe screens (styles.css V8 wardrobe grid
/// + V9 clothing details / import flow).
abstract final class WardrobeTokens {
  // Header / stats (.w-head / .w-stats)
  static const subtitle = Color(0xFF88918B);
  static const headerActionBorder = Color(0xFFE6EBE6);
  static const headerActionInk = Color(0xFF52685B);
  static const statBorder = Color(0xFFE9EEE9);
  static const statBg = Color(0xFFFBFCFB);
  static const statValue = Color(0xFF1C2C22);
  static const statLabel = Color(0xFF8C9990);

  // Actions row (.w-add / .w-build)
  static const addBg = Color(0xFF087F62);
  static const buildBorder = Color(0xFFD5E4D9);
  static const buildInk = Color(0xFF087358);

  // Search (.w-search)
  static const searchBg = Color(0xFFF8F9F7);
  static const searchBorder = Color(0xFFE7ECE7);
  static const searchIcon = Color(0xFF87948A);
  static const searchInk = Color(0xFF21332A);
  static const searchShortcut = Color(0xFFABB5AD);

  // Category chips (.w-category)
  static const categoryBorder = Color(0xFFE7EAE6);
  static const categoryInk = Color(0xFF647168);
  static const categoryActiveBg = Color(0xFF087F62);

  // Section header (.w-section-header)
  static const sectionCount = Color(0xFF9BA69C);
  static const sectionLink = Color(0xFF087F62);

  // Tiles / empty state (.w-tile / .w-empty)
  static const tilePhotoBg = Color(0xFFF6F7F4);
  static const tilePhotoBorder = Color(0xFFF0F1EE);
  static const tileIconBg = Color(0xDBFFFFFF);
  static const tileIconInk = Color(0xFF557463);
  static const tileSub = Color(0xFF94A098);
  static const emptyBorder = Color(0xFFDCE7DF);
  static const emptyIcon = Color(0xFF087F62);
  static const emptyBody = Color(0xFF85938A);

  // AI action (.w-ai-action)
  static const aiBg = Color(0xFFEDF6F0);
  static const aiBorder = Color(0xFFDCECE1);
  static const aiInk = Color(0xFF09664E);
  static const aiSub = Color(0xFF728E7C);

  // Clothing details / edit (.w-eyebrow / .w-detail-* / .w-edit-*)
  static const eyebrow = Color(0xFF087F62);
  static const moreButtonBorder = Color(0xFFE2E9E4);
  static const moreButtonInk = Color(0xFF315B47);
  static const detailPhotoBg = Color(0xFFF5F6F2);
  static const photoLabelBg = Color(0xEDFFFFFF);
  static const photoLabelBorder = Color(0xFFE5EBE6);
  static const photoLabelInk = Color(0xFF396D55);
  static const attributesBorder = Color(0xFFE6EBE7);
  static const attributeLabel = Color(0xFF8B988E);
  static const detailNoteBg = Color(0xFFF3F8F4);
  static const detailNoteBody = Color(0xFF74857B);
  static const removeInk = Color(0xFFAD5A57);
  static const actionBorder = Color(0xFFE5EAE5);
  static const editHeroBorder = Color(0xFFE8EDE8);
  static const editHeroBody = Color(0xFF8A958C);

  // Import flow (.w-import-* / .w-count-row / .w-sample-grid / .w-process /
  // .w-review-* / .w-complete-*)
  static const importMonogramBg = Color(0xFFEEF7F1);
  static const importChoiceBorder = Color(0xFFE3EBE5);
  static const importChoiceInk = Color(0xFF24362B);
  static const importChoiceSub = Color(0xFF8B988D);
  static const importChoiceIconBg = Color(0xFFF0F7F2);
  static const infoLineBg = Color(0xFFEEF6F1);
  static const infoLineInk = Color(0xFF527360);
  static const countRowBorder = Color(0xFFE2E8E3);
  static const countRowInk = Color(0xFF758177);
  static const countRowActiveBg = Color(0xFFEAF5EE);
  static const countRowActiveInk = Color(0xFF086E52);
  static const countRowActiveBorder = Color(0xFF8BCBB0);
  static const sampleGridBg = Color(0xFFF5F6F3);
  static const summaryBorder = Color(0xFFE5EBE6);
  static const summaryInk = Color(0xFF89958D);
  static const summaryStrong = Color(0xFF23543B);
  static const processIcon = Color(0xFF087F62);
  static const processBody = Color(0xFF86938A);
  static const processCaption = Color(0xFF8CA092);
  static const reviewProgress = Color(0xFF789080);
  static const reviewPhotoBg = Color(0xFFF5F6F2);
  static const reviewPhotoLabel = Color(0xFF567763);
  static const reviewToggle = Color(0xFF087F62);
  static const completeCheckBg = Color(0xFFE5F5EB);
  static const completeCheckInk = Color(0xFF087F62);
  static const completeBody = Color(0xFF87938B);
  static const completeStatBorder = Color(0xFFE4EBE5);
}
