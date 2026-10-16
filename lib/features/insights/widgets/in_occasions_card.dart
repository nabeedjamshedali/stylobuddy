import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../insights_tokens.dart';

/// Prototype `.in-card.in-occasions`: `'<name>' '<n> pieces'` rows, verbatim
/// (no pluralisation, so 'Date Night' reads '1 pieces').
class InOccasionsCard extends StatelessWidget {
  const InOccasionsCard({super.key, required this.occasions});

  final List<(String, int)> occasions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: InsightsTokens.cardBorder),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          for (var i = 0; i < occasions.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(occasions[i].$1, style: AppTextStyles.dmSans(size: 11)),
                Text(
                  '${occasions[i].$2} pieces',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w700,
                    color: InsightsTokens.occasionValue,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
