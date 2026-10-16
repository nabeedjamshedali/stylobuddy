import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../home_tokens.dart';

/// Prototype `.h-tool-grid`: the 4 "Explore more" rows.
class HomeExploreGrid extends StatelessWidget {
  const HomeExploreGrid({super.key});

  static const _items = [
    (
      icon: '▤',
      title: 'Packing assistant',
      subtitle: 'Pack smarter for trips',
      route: AppRoutes.packing,
    ),
    (
      icon: '◉',
      title: 'Style insights',
      subtitle: 'Discover wardrobe trends',
      route: AppRoutes.insights,
    ),
    (
      icon: '♧',
      title: 'Shopping assistant',
      subtitle: 'Find your wardrobe gaps',
      route: AppRoutes.shopping,
    ),
    (
      icon: '♡',
      title: 'Saved outfits',
      subtitle: 'Your favorite looks',
      route: AppRoutes.saved,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _ToolRow(item: _items[row * 2])),
              const SizedBox(width: 8),
              Expanded(child: _ToolRow(item: _items[row * 2 + 1])),
            ],
          ),
        ],
      ],
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.item});

  final ({String icon, String title, String subtitle, String route}) item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(item.route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: HomeTokens.toolBorder),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Text(
              item.icon,
              style: AppTextStyles.dmSans(size: 19, color: HomeTokens.toolIcon),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.dmSans(
                      size: 9.5,
                      weight: FontWeight.w700,
                      height: 1.2,
                      color: HomeTokens.toolTitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.dmSans(
                      size: 8.5,
                      height: 1.35,
                      color: HomeTokens.toolSub,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '›',
              style: AppTextStyles.dmSans(
                size: 17,
                color: HomeTokens.toolArrow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
