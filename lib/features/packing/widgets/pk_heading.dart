import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../packing_tokens.dart';

/// Prototype `.pk-eyebrow` + `h2` + `.pk-sub`: reused by `/packing`,
/// `/new-trip`, `/packing-preview` and `/packing-add`.
class PkHeading extends StatelessWidget {
  const PkHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: AppTextStyles.dmSans(
            size: 9,
            weight: FontWeight.w800,
            letterSpacing: 1.6,
            color: PackingTokens.eyebrow,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 7),
          child: Text(
            title,
            style: AppTextStyles.manrope(
              size: 23,
              weight: FontWeight.w700,
              letterSpacing: -0.7,
              height: 1.18,
            ),
          ),
        ),
        Text(
          subtitle,
          style: AppTextStyles.dmSans(
            size: 11,
            color: PackingTokens.subtitle,
            height: 1.7,
          ),
        ),
      ],
    );
  }
}
