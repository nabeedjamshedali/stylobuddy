import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../insights_tokens.dart';

/// Prototype `.in-stats`: WARDROBE / LOGGED WEARS / EVER WORN.
class InStatCards extends StatelessWidget {
  const InStatCards({
    super.key,
    required this.wardrobe,
    required this.loggedWears,
    required this.everWorn,
  });

  final int wardrobe;
  final int loggedWears;
  final int everWorn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Card(label: 'WARDROBE', value: wardrobe, caption: 'clothing pieces')),
        const SizedBox(width: 7),
        Expanded(
          child: _Card(
            label: 'LOGGED WEARS',
            value: loggedWears,
            caption: 'outfit wear entries',
          ),
        ),
        const SizedBox(width: 7),
        Expanded(child: _Card(label: 'EVER WORN', value: everWorn, caption: 'tracked pieces')),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.label, required this.value, required this.caption});

  final String label;
  final int value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: InsightsTokens.statBg,
        border: Border.all(color: InsightsTokens.statBorder),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 8,
              weight: FontWeight.w700,
              letterSpacing: 0.6,
              color: InsightsTokens.statLabel,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$value',
            style: AppTextStyles.dmSans(
              size: 23,
              weight: FontWeight.w700,
              height: 1.2,
              color: InsightsTokens.statValue,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: AppTextStyles.dmSans(size: 9, color: InsightsTokens.statCaption),
          ),
        ],
      ),
    );
  }
}
