import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../matching_tokens.dart';

/// Prototype `.mm-heading`: `STEP N OF 3` eyebrow, headline and sub-copy.
class MmStepHeading extends StatelessWidget {
  const MmStepHeading({
    super.key,
    required this.step,
    required this.title,
    required this.description,
    this.descriptionSpans,
  });

  final String step;
  final String title;
  final String description;

  /// Overrides [description] with rich text (e.g. a bolded word) when set.
  final List<InlineSpan>? descriptionSpans;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step,
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w800,
              letterSpacing: 1.5,
              color: MatchingTokens.kicker,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.manrope(
              size: 21,
              weight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -.75,
              color: MatchingTokens.headingInk,
            ),
          ),
          const SizedBox(height: 10),
          descriptionSpans == null
              ? Text(
                  description,
                  style: AppTextStyles.dmSans(
                    size: 12,
                    height: 1.6,
                    color: AppColors.muted,
                  ),
                )
              : Text.rich(
                  TextSpan(
                    style: AppTextStyles.dmSans(
                      size: 12,
                      height: 1.6,
                      color: AppColors.muted,
                    ),
                    children: descriptionSpans,
                  ),
                ),
        ],
      ),
    );
  }
}
