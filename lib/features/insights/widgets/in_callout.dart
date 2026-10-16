import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../insights_tokens.dart';

/// Prototype `.in-callout`: 'Put your wardrobe to work' -> 'Match My
/// Clothes →'.
class InCallout extends StatelessWidget {
  const InCallout({super.key, required this.onMatch});

  final VoidCallback onMatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InsightsTokens.calloutBg,
        border: Border.all(color: InsightsTokens.calloutBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✧',
            style: AppTextStyles.dmSans(size: 23, color: InsightsTokens.calloutIcon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Put your wardrobe to work',
                  style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Find new combinations for clothes you already own.',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    height: 1.5,
                    color: InsightsTokens.calloutBody,
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: InsightsTokens.calloutButtonBg,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onMatch,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(
                        'Match My Clothes →',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
