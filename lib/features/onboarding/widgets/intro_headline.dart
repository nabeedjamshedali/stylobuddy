import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../onboarding_tokens.dart';

/// `.ob-headline`: centered title and description under the illustration.
class IntroHeadline extends StatelessWidget {
  const IntroHeadline({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Column(
        children: [
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.manrope(
              size: 18,
              weight: FontWeight.w600,
              height: 1.28,
              letterSpacing: -.45,
              color: OnboardingTokens.headlineTitle,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 248),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans(
                size: 10.6,
                height: 1.58,
                color: OnboardingTokens.headlineBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
