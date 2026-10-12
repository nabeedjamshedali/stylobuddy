import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_pill_button.dart';

/// Page-dot indicator + the CTA pill button, shared across onboarding
/// pages 2 and 3 (page 1 embeds its own CTA inline with the hero photo).
class OnboardingBottomControls extends StatelessWidget {
  final PageController controller;
  final int pageCount;
  final String ctaLabel;
  final VoidCallback onPressed;

  const OnboardingBottomControls({
    super.key,
    required this.controller,
    required this.pageCount,
    required this.ctaLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SmoothPageIndicator(
          controller: controller,
          count: pageCount,
          effect: const ExpandingDotsEffect(
            dotHeight: 7,
            dotWidth: 7,
            spacing: 6,
            activeDotColor: AppColors.accent,
            dotColor: AppColors.dotInactive,
          ),
        ),
        const SizedBox(height: 18),
        PrimaryPillButton(label: ctaLabel, onPressed: onPressed),
      ],
    );
  }
}
