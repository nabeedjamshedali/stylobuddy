import 'package:flutter/material.dart';

/// CSS values used only by the saved looks / wear history screens
/// (styles.css `.sl-*`, V14).
abstract final class SavedTokens {
  // Header (.sl-kicker / .sl-heading / .sl-total)
  static const kicker = Color(0xFF147657);
  static const subtitle = Color(0xFF87958B);
  static const greenAccent = Color(0xFF0B8A64);
  static const total = Color(0xFF0B7859);
  static const totalLabel = Color(0xFF97A39B);

  // Stats (.sl-stats)
  static const statBorder = Color(0xFFEDF0EC);
  static const statBg = Color(0xFFF6F8F6);
  static const statValue = Color(0xFF26382C);
  static const statLabel = Color(0xFF87968C);

  // Tabs (.sl-tabs)
  static const tabsBorder = Color(0xFFE5EBE6);
  static const tabInactive = Color(0xFF96A197);
  static const tabActive = Color(0xFF087D59);
  static const tabActiveBorder = Color(0xFF0A8964);

  // Search (.sl-search)
  static const searchBorder = Color(0xFFE6ECE6);
  static const searchBg = Color(0xFFF8FAF8);
  static const searchIcon = Color(0xFF81958A);
  static const searchInk = Color(0xFF22332A);

  // List headers (.sl-list-title / .sl-section-header)
  static const listCount = Color(0xFF9CA69E);
  static const sectionLink = Color(0xFF0D7958);

  // Gallery card (.sl-look / .sl-image / .sl-card-heart / .sl-look-copy)
  static const cardBorder = Color(0xFFE7ECE7);
  static const cardShadow = Color(0x06142C1C);
  static const imageBg = Color(0xFFF6F6F3);
  static const heartInk = Color(0xFF0D7557);
  static const label = Color(0xFF8E9B90);
  static const footDivider = Color(0xFFEFF2EF);
  static const footMuted = Color(0xFF88988D);
  static const footStrong = Color(0xFF097B59);

  // Wear timeline (.sl-wear-entry / .sl-wear-thumb / .sl-wear-info)
  static const entryBorder = Color(0xFFE5EBE6);
  static const thumbBg = Color(0xFFF6F7F4);
  static const dateInk = Color(0xFF0B8663);
  static const entrySub = Color(0xFF93A096);
  static const chevron = Color(0xFF90A095);

  // Empty state (.sl-empty)
  static const emptyBorder = Color(0xFFD9E6DC);
  static const emptyBg = Color(0xFFFBFDFA);
  static const emptyIcon = Color(0xFF0A8C62);
  static const emptyBody = Color(0xFF91A095);

  // Footer actions (.sl-footer-action)
  static const footerBorder = Color(0xFFDCE9DF);
  static const footerBg = Color(0xFFF8FCF9);
  static const footerInk = Color(0xFF08684D);

  // Detail (.sl-detail / .sl-hero / .sl-tags)
  static const heroBg = Color(0xFFF5F6F2);
  static const heroBorder = Color(0xFFEEF0EB);
  static const tagBg = Color(0xFFECF6EF);
  static const tagInk = Color(0xFF197357);

  // Garment rows (.sl-garments)
  static const garmentBorder = Color(0xFFEDF0EC);
  static const garmentPhotoBg = Color(0xFFF6F7F5);
  static const garmentSub = Color(0xFF929F95);
  static const garmentChevron = Color(0xFF92A198);

  // Style note (.sl-explanation)
  static const noteBg = Color(0xFFF0F7F2);
  static const noteBorder = Color(0xFFE5F0E7);
  static const noteLabel = Color(0xFF087956);
  static const noteBody = Color(0xFF5E7165);

  // Wear note / action grid / delete (.sl-wear-note / .sl-action-grid / .sl-delete)
  static const wearNote = Color(0xFF8B9A8F);
  static const actionBorder = Color(0xFFDFE9E2);
  static const actionInk = Color(0xFF147457);
  static const actionLabel = Color(0xFF526B5B);
  static const deleteInk = Color(0xFFAC5E60);
}
