import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../wardrobe_tokens.dart';

/// Prototype `.w-ai-action`: 'Find your best matches' banner -> /matching.
class WardrobeAiAction extends StatelessWidget {
  const WardrobeAiAction({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WardrobeTokens.aiBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WardrobeTokens.aiBorder),
          ),
          child: Row(
            children: [
              Text(
                '✧',
                style: AppTextStyles.dmSans(
                  size: 23,
                  color: WardrobeTokens.aiInk,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find your best matches',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w700,
                        color: WardrobeTokens.aiInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select wardrobe pieces and let AI style them.',
                      style: AppTextStyles.dmSans(
                        size: 9.5,
                        color: WardrobeTokens.aiSub,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '↗',
                style: AppTextStyles.dmSans(
                  size: 17,
                  color: WardrobeTokens.aiInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
