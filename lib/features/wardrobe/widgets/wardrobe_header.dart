import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../wardrobe_tokens.dart';

/// Prototype `.w-head`: overline / title / subtitle plus the filter icon.
class WardrobeHeader extends StatelessWidget {
  const WardrobeHeader({super.key, required this.onFilter});

  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR COLLECTION',
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w800,
                  letterSpacing: 1.65,
                  color: AppColors.brandGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'My Wardrobe',
                style: AppTextStyles.manrope(
                  size: 24,
                  weight: FontWeight.w700,
                  letterSpacing: -0.95,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Everything you own, beautifully organized.',
                style: AppTextStyles.dmSans(
                  size: 10.6,
                  color: WardrobeTokens.subtitle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          label: 'Wardrobe filters',
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onFilter,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: WardrobeTokens.headerActionBorder),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                '☷',
                style: AppTextStyles.dmSans(
                  size: 17,
                  color: WardrobeTokens.headerActionInk,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
