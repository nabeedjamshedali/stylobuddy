import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/onboarding_page_data.dart';
import 'onboarding_headline.dart';
import 'onboarding_top_bar.dart';

/// Mirrors reference screen 2: a centered model card with a 360° rotate
/// affordance and a row of outfit-piece thumbnails underneath.
class AiStylistPage extends StatelessWidget {
  final OnboardingPageData data;
  final VoidCallback onSkip;

  const AiStylistPage({super.key, required this.data, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OnboardingTopBar(onSkip: onSkip),
            const SizedBox(height: 28),
            OnboardingHeadline(data: data),
            const SizedBox(height: 10),
            Text(data.subtitle, style: AppTextStyles.body),
            const SizedBox(height: 24),
            Expanded(child: _RotateCard()),
            const SizedBox(height: 18),
            _ThumbnailRow(),
          ],
        ),
      ),
    );
  }
}

class _RotateCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3A2E27), Color(0xFF17140F)],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.person_outline,
              size: 96,
              color: AppColors.textMuted,
            ),
            Positioned(
              bottom: 56,
              child: Text('360°', style: AppTextStyles.cardTitle),
            ),
            Positioned(
              bottom: 24,
              child: Row(
                children: [
                  _CircleArrow(icon: Icons.chevron_left),
                  const SizedBox(width: 90),
                  _CircleArrow(icon: Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleArrow extends StatelessWidget {
  final IconData icon;
  const _CircleArrow({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.glassFill,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 18),
    );
  }
}

class _ThumbnailRow extends StatelessWidget {
  static const _icons = [
    Icons.checkroom_outlined,
    Icons.dry_cleaning_outlined,
    Icons.local_mall_outlined,
    Icons.hiking_outlined,
    Icons.backpack_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _icons.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final selected = i == 2;
          return Container(
            width: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.surfaceMuted,
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.glassBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: Icon(_icons[i], color: AppColors.textSecondary, size: 20),
          );
        },
      ),
    );
  }
}
