import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../stylist_tokens.dart';

/// Prototype `.ai-factor-grid`: four "what makes a good match" tiles.
class StudioFactorGrid extends StatelessWidget {
  const StudioFactorGrid({super.key});

  static const _factors = [
    ('01', 'Shape & silhouette', 'Well-balanced proportions'),
    ('02', 'Texture & fabric', 'Material coordination'),
    ('03', 'Occasion & weather', 'Appropriate for your day'),
    ('04', 'Color & personality', 'Looks that feel like you'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 9),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < 2; c++) ...[
                  if (c > 0) const SizedBox(width: 9),
                  Expanded(child: _Factor(_factors[row * 2 + c])),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Factor extends StatelessWidget {
  const _Factor(this.data);

  final (String, String, String) data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 105),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
      decoration: BoxDecoration(
        color: StylistTokens.factorBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.$1,
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w800,
              color: StylistTokens.factorIndex,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            data.$2,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            data.$3,
            style: AppTextStyles.dmSans(
              size: 9,
              height: 1.4,
              color: StylistTokens.factorSub,
            ),
          ),
        ],
      ),
    );
  }
}
