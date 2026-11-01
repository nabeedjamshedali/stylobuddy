import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../profile_tokens.dart';

/// Prototype `.pf-benefits`: the planned-premium-value list, `P/app.js:284`.
class PfBenefitsCard extends StatelessWidget {
  const PfBenefitsCard({super.key, required this.benefits});

  final List<String> benefits;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: ProfileTokens.benefitBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < benefits.length; i++)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: i == benefits.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: ProfileTokens.benefitDivider),
                      ),
              ),
              child: Row(
                children: [
                  const Text(
                    '✓',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ProfileTokens.benefitMark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(benefits[i], style: AppTextStyles.dmSans(size: 11)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
