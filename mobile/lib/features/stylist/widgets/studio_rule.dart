import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../stylist_tokens.dart';

/// Prototype `.ai-rule`: tick + "Only clothes you own." line.
class StudioRule extends StatelessWidget {
  const StudioRule({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 25),
      child: Row(
        children: [
          Container(
            width: 23,
            height: 23,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: StylistTokens.ruleTickBg,
              shape: BoxShape.circle,
            ),
            child: Text(
              '✓',
              style: AppTextStyles.dmSans(
                size: 11,
                color: StylistTokens.featureIconInk,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Only clothes you own. No imaginary items.',
              style: AppTextStyles.dmSans(
                size: 11,
                color: StylistTokens.ruleInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
