import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../profile_tokens.dart';

/// Prototype `.pf-paywall`: the `/premium` hero card, `P/app.js:284`.
class PfPaywallCard extends StatelessWidget {
  const PfPaywallCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 27),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment(-.5, -1),
          end: Alignment(.5, 1),
          colors: [
            ProfileTokens.paywallGradientStart,
            ProfileTokens.paywallGradientEnd,
          ],
        ),
      ),
      child: Column(
        children: [
          const Text('✧', style: TextStyle(fontSize: 32, color: AppColors.white)),
          const SizedBox(height: 8),
          Text(
            'STYLOBUDDY PLUS',
            style: AppTextStyles.dmSans(
              size: 9,
              letterSpacing: 2,
              color: ProfileTokens.paywallKicker,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'More possibilities.\nMore personal style.',
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans(
                size: 23,
                color: AppColors.white,
                height: 1.22,
                letterSpacing: -.8,
              ),
            ),
          ),
          Text(
            'Explore the premium experience before final pricing and usage '
            'limits are confirmed.',
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 11,
              color: ProfileTokens.paywallBody,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
