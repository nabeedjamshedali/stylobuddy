import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/placeholder_photo.dart';
import '../models/onboarding_page_data.dart';
import 'onboarding_headline.dart';

/// Mirrors reference screen 1: full-bleed portrait photo behind a
/// headline + subtitle, with an "Upload Your Photo" feature card above
/// the CTA.
class HeroUploadPage extends StatelessWidget {
  final OnboardingPageData data;

  const HeroUploadPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const PlaceholderPhoto(icon: Icons.person_outline),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.45, 0.75, 1.0],
              colors: [
                AppColors.background.withValues(alpha: 0.0),
                AppColors.background.withValues(alpha: 0.35),
                AppColors.background.withValues(alpha: 0.92),
                AppColors.background,
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingHeadline(data: data),
                const SizedBox(height: 10),
                Text(data.subtitle, style: AppTextStyles.body),
                const SizedBox(height: 20),
                _UploadFeatureCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadFeatureCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.file_upload_outlined,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upload Your Photo', style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(
                  'Let AI understand your vibe and style preferences',
                  style: AppTextStyles.cardSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
