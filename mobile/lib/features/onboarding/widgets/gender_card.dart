import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../onboarding_tokens.dart';
import 'ob_photo.dart';

/// Prototype v26 `.v26-gender-card` (V26.1 contained-art fit): copy column
/// on the left (title, subtitle, radio), artwork contained on the right.
/// Both cards share this one widget, so they always get identical size,
/// weight and treatment (F24 anti-goal: female path never visually weaker).
class GenderCard extends StatelessWidget {
  const GenderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;

  /// File name under `assets/onboarding/`.
  final String image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: selected
                ? OnboardingTokens.genderCardChosenBg
                : OnboardingTokens.genderCardBg,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected
                  ? OnboardingTokens.genderAccent
                  : OnboardingTokens.genderCardBorder,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.fromLTRB(17, 15, 4, 15),
          child: Row(
            children: [
              Expanded(
                flex: 47,
                child: _CardCopy(
                  title: title,
                  subtitle: subtitle,
                  selected: selected,
                ),
              ),
              Expanded(
                flex: 53,
                child: FractionallySizedBox(
                  heightFactor: .9,
                  child: ObPhoto(file: image),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardCopy extends StatelessWidget {
  const _CardCopy({
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.dmSans(
            size: 22,
            weight: FontWeight.w700,
            letterSpacing: -.4,
            color: OnboardingTokens.genderTitle,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 145),
          child: Text(
            subtitle,
            style: AppTextStyles.dmSans(
              size: 11,
              height: 1.4,
              color: OnboardingTokens.genderCardSub,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 21,
          height: 21,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? OnboardingTokens.genderAccent : null,
            border: Border.all(
              color: selected
                  ? OnboardingTokens.genderAccent
                  : OnboardingTokens.genderRadioBorder,
              width: 1.5,
            ),
          ),
          child: selected
              ? Text(
                  '✓',
                  style: AppTextStyles.dmSans(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
