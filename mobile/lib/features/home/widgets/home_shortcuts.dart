import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../home_tokens.dart';

const _aiOutfitsSvg =
    '<svg viewBox="0 0 24 24" fill="none" stroke="#087F62" stroke-width="1.8">'
    '<path d="m12 3 1.6 5.4L19 10l-5.4 1.6L12 17l-1.6-5.4L5 10l5.4-1.6L12 3Z"/>'
    '<path d="m19 16 .6 2.4L22 19l-2.4.6L19 22l-.6-2.4L16 19l2.4-.6L19 16Z"/></svg>';

const _matchItemsSvg =
    '<svg viewBox="0 0 24 24" fill="none" stroke="#087F62" stroke-width="1.8">'
    '<path d="M8 4v3l-4 3v10h16V10l-4-3V4"/><path d="M8 4h8v8H8z"/>'
    '<path d="M8 15h8"/></svg>';

const _addItemSvg =
    '<svg viewBox="0 0 24 24" fill="none" stroke="#087F62" stroke-width="1.8">'
    '<rect x="4" y="4" width="16" height="16" rx="3"/>'
    '<path d="M12 7v10M7 12h10"/></svg>';

const _calendarSvg =
    '<svg viewBox="0 0 24 24" fill="none" stroke="#087F62" stroke-width="1.8">'
    '<rect x="3" y="5" width="18" height="16" rx="2"/>'
    '<path d="M7 3v4M17 3v4M3 10h18M8 14h3v3H8z"/></svg>';

/// Prototype `.h-shortcuts`: the 4 quick-action buttons.
class HomeShortcuts extends StatelessWidget {
  const HomeShortcuts({super.key});

  static const _items = [
    (svg: _aiOutfitsSvg, label: 'AI Outfits', route: AppRoutes.occasion),
    (svg: _matchItemsSvg, label: 'Match Items', route: AppRoutes.matching),
    (svg: _addItemSvg, label: 'Add Item', route: AppRoutes.import),
    (svg: _calendarSvg, label: 'Calendar', route: AppRoutes.calendar),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(width: 9),
          Expanded(child: _Shortcut(item: _items[i])),
        ],
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.item});

  final ({String svg, String label, String route}) item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(item.route),
      child: Container(
        height: 79,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: HomeTokens.shortcutBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 33,
              height: 33,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HomeTokens.shortIconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.string(item.svg, width: 20, height: 20),
            ),
            const SizedBox(height: 9),
            Text(
              item.label,
              style: AppTextStyles.dmSans(
                size: 10,
                weight: FontWeight.w600,
                color: HomeTokens.shortcutInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
