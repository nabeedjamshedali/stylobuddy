import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../builder_tokens.dart';

/// Prototype `.mb-categories`: horizontally scrolling category chip row.
class MbCategories extends StatelessWidget {
  const MbCategories({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  static const all = [
    'All',
    'Shirts',
    'Pants',
    'Dresses',
    'Skirts',
    'Outerwear',
    'Shoes',
    'Accessories',
  ];

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 12),
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
    return Material(
      color: active ? BuilderTokens.chipActiveBg : AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? BuilderTokens.chipActiveBg : BuilderTokens.chipBorder,
            ),
          ),
          child: Text(
            label,
            softWrap: false,
            style: AppTextStyles.dmSans(
              size: 10,
              color: active ? AppColors.white : BuilderTokens.chipInk,
            ),
          ),
        ),
      ),
    );
  }
}
