import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/intro_slide.dart';
import '../onboarding_tokens.dart';

/// Slide 4 body: heading, caption and the toggleable occasion rows.
class OccasionList extends StatelessWidget {
  const OccasionList({super.key, required this.chosen, required this.onToggle});

  final Set<String> chosen;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 14, 9, 0),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            'Tell us where\nyou’re going.',
            textAlign: TextAlign.center,
            style: AppTextStyles.manrope(
              size: 20,
              weight: FontWeight.w600,
              height: 1.15,
              letterSpacing: -.55,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We’ll personalize recommendations\nbased on the occasion.',
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 10.4,
              height: 1.45,
              color: OnboardingTokens.occasionsBody,
            ),
          ),
          const SizedBox(height: 18),
          for (final (glyph, name) in introOccasions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OccasionRow(
                glyph: glyph,
                name: name,
                chosen: chosen.contains(name),
                onTap: () => onToggle(name),
              ),
            ),
        ],
      ),
    );
  }
}

class _OccasionRow extends StatelessWidget {
  const _OccasionRow({
    required this.glyph,
    required this.name,
    required this.chosen,
    required this.onTap,
  });

  final String glyph;
  final String name;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        key: Key(chosen ? 'occasion-$name-chosen' : 'occasion-$name'),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: chosen ? OnboardingTokens.eventChosenBg : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: chosen
                ? OnboardingTokens.eventChosenBorder
                : OnboardingTokens.eventBorder,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: Text(
                glyph,
                style: AppTextStyles.dmSans(
                  size: 14,
                  color: OnboardingTokens.eventGlyph,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.dmSans(
                  size: 12,
                  color: chosen
                      ? OnboardingTokens.eventChosenInk
                      : OnboardingTokens.eventInk,
                ),
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: chosen ? OnboardingTokens.eventChosenBorder : null,
                border: Border.all(
                  color: chosen
                      ? OnboardingTokens.choiceDotRing
                      : OnboardingTokens.choiceDotBorder,
                  width: chosen ? 3 : 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
