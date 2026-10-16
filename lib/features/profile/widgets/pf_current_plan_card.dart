import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../profile_tokens.dart';

/// Prototype `.pf-current-plan`: the `/subscription` hero card,
/// `P/app.js:287`.
class PfCurrentPlanCard extends StatelessWidget {
  const PfCurrentPlanCard({
    super.key,
    required this.plan,
    required this.onExplore,
  });

  final String plan;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 22),
      decoration: BoxDecoration(
        color: ProfileTokens.currentPlanBg,
        border: Border.all(color: ProfileTokens.currentPlanBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT PLAN',
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w700,
              letterSpacing: 1.5,
              color: ProfileTokens.currentPlanLabel,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(plan, style: AppTextStyles.dmSans(size: 27)),
          ),
          Text(
            'Subscription pricing and included AI usage are still under '
            'review.',
            style: AppTextStyles.dmSans(
              size: 11,
              color: ProfileTokens.currentPlanBody,
              height: 1.7,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onExplore,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Explore StyloBuddy Plus →',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w700,
                  color: ProfileTokens.currentPlanLink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
