import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../wardrobe_tokens.dart';

/// Prototype `.w-section-header`: section title + count + 'Filter ☷'.
class WardrobeSectionHeader extends StatelessWidget {
  const WardrobeSectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.onFilter,
  });

  final String title;
  final int count;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              title,
              style: AppTextStyles.manrope(
                size: 15,
                weight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              '$count items',
              style: AppTextStyles.dmSans(
                size: 9,
                color: WardrobeTokens.sectionCount,
              ),
            ),
          ],
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onFilter,
          child: Text(
            'Filter ☷',
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.w700,
              color: WardrobeTokens.sectionLink,
            ),
          ),
        ),
      ],
    );
  }
}
