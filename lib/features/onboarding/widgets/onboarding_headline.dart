import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../models/onboarding_page_data.dart';

/// Renders the page's headline with the accent word highlighted in the
/// brand color, e.g. "Redefine Your **Style** with AI".
class OnboardingHeadline extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingHeadline({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final parts = data.headlineParts;
    return RichText(
      text: TextSpan(
        style: AppTextStyles.headline,
        children: [
          TextSpan(text: parts.first),
          TextSpan(
            text: data.headlineAccentWord,
            style: AppTextStyles.headlineAccent,
          ),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
    );
  }
}
