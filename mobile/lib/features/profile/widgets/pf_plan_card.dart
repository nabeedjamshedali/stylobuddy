import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../profile_tokens.dart';

/// Prototype `.pf-plan-choice`: a billing-cycle option on `/plan`,
/// `P/app.js:285`.
class PfPlanCard extends StatelessWidget {
  const PfPlanCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 121),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? ProfileTokens.choiceSelectedBg : AppColors.white,
          border: Border.all(
            color: selected
                ? ProfileTokens.choiceSelectedBorder
                : ProfileTokens.choiceBorder,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.dmSans(
                size: 14,
                weight: FontWeight.w700,
                color: selected
                    ? ProfileTokens.choiceSelectedInk
                    : ProfileTokens.choiceInk,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              subtitle,
              style: AppTextStyles.dmSans(size: 10, color: ProfileTokens.planSubtitle),
            ),
            const Spacer(),
            Text(
              'Price TBD',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w700,
                color: selected
                    ? ProfileTokens.choiceSelectedInk
                    : ProfileTokens.choiceInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
