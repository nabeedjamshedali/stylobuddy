import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../profile_tokens.dart';

/// Prototype `.pf-premium`: the profile-page banner that opens `/premium`.
class PfPremiumBanner extends StatelessWidget {
  const PfPremiumBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileTokens.premiumGradientStart,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 21),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment(-.8, -1),
              end: Alignment(.8, 1),
              colors: [
                ProfileTokens.premiumGradientStart,
                ProfileTokens.premiumGradientEnd,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ProfileTokens.premiumStarBorder),
                ),
                child: const Text(
                  '✧',
                  style: TextStyle(fontSize: 32, color: AppColors.white),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'STYLOBUDDY PLUS',
                      style: AppTextStyles.dmSans(
                        size: 9,
                        letterSpacing: 1.3,
                        color: ProfileTokens.premiumKicker,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Make every outfit count.',
                      style: AppTextStyles.dmSans(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Explore premium styling tools →',
                      style: AppTextStyles.dmSans(
                        size: 10,
                        color: ProfileTokens.premiumEm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
