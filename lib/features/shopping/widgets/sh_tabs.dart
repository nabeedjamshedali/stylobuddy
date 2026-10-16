import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../shopping_tokens.dart';

/// Prototype `.sh-tabs`: 'Discover n' / 'Wishlist n'.
class ShTabs extends StatelessWidget {
  const ShTabs({
    super.key,
    required this.tab,
    required this.discoverCount,
    required this.wishlistCount,
    required this.onSelect,
  });

  final String tab;
  final int discoverCount;
  final int wishlistCount;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ShoppingTokens.tabsBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: 'Discover',
              count: discoverCount,
              active: tab == 'discover',
              onTap: () => onSelect('discover'),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _Tab(
              label: 'Wishlist',
              count: wishlistCount,
              active: tab == 'wishlist',
              onTap: () => onSelect('wishlist'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? ShoppingTokens.tabActiveBg : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w700,
                      color: active
                          ? ShoppingTokens.tabActiveInk
                          : ShoppingTokens.tabInactive,
                    ),
                  ),
                  TextSpan(
                    text: ' $count',
                    style: AppTextStyles.dmSans(
                      size: 10,
                      weight: FontWeight.w600,
                      color: (active
                              ? ShoppingTokens.tabActiveInk
                              : ShoppingTokens.tabCount)
                          .withValues(alpha: .7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
