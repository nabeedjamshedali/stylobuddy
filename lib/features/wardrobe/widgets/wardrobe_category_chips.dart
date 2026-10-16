import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../wardrobe_tokens.dart';

/// Prototype `wardrobeCats` chip scroller: All + the 7 categories.
class WardrobeCategoryChips extends StatelessWidget {
  const WardrobeCategoryChips({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  static const categories = [
    'All',
    'Shirts',
    'Pants',
    'Shoes',
    'Dresses',
    'Skirts',
    'Outerwear',
    'Accessories',
  ];

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 7),
            _Chip(
              label: categories[i],
              active: selected == categories[i],
              onTap: () => onSelect(categories[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? WardrobeTokens.categoryActiveBg : AppColors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active
                ? WardrobeTokens.categoryActiveBg
                : WardrobeTokens.categoryBorder,
          ),
        ),
        child: Text(
          label,
          softWrap: false,
          style: AppTextStyles.dmSans(
            size: 10,
            weight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? AppColors.white : WardrobeTokens.categoryInk,
          ),
        ),
      ),
    );
  }
}
