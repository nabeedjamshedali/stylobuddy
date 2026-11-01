import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../stylist_tokens.dart';

/// Prototype `.ai-no-matches` empty state.
class NoMatches extends StatelessWidget {
  const NoMatches({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: StylistTokens.noMatchesBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'No valid combinations yet',
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 16,
              weight: FontWeight.w700,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Try including another garment category or adjusting mandatory selections.',
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 11,
              color: StylistTokens.noMatchesInk,
            ),
          ),
        ],
      ),
    );
  }
}
