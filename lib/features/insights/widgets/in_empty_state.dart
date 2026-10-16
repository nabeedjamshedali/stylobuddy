import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../insights_tokens.dart';

/// Prototype `insightEmpty()`, `P/app.js:330`.
class InEmptyState extends StatelessWidget {
  const InEmptyState({super.key, required this.onAddClothing});

  final VoidCallback onAddClothing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 18),
      child: Column(
        children: [
          Text(
            '▦',
            style: AppTextStyles.dmSans(size: 38, color: InsightsTokens.emptyIcon),
          ),
          const SizedBox(height: 12),
          Text(
            'Insights start with your wardrobe',
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(size: 17, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first clothing pieces to see category breakdowns, '
            'style patterns and wearing habits.',
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 11,
              height: 1.7,
              color: InsightsTokens.emptyBody,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Add clothing', onPressed: onAddClothing, fullWidth: false),
        ],
      ),
    );
  }
}
