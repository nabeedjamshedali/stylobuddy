import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/placeholder_photo.dart';
import '../models/onboarding_page_data.dart';
import 'onboarding_headline.dart';
import 'onboarding_top_bar.dart';

/// Mirrors reference screen 3: a product detail-style card (color swatches,
/// photo, name, price-with-discount row) used here to illustrate the
/// "curated picks" value proposition rather than a real product.
class CuratedPicksPage extends StatelessWidget {
  final OnboardingPageData data;
  final VoidCallback onSkip;

  const CuratedPicksPage({super.key, required this.data, required this.onSkip});

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
            Expanded(child: _ProductCard()),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  static const _swatches = [
    Color(0xFF17140F),
    Color(0xFF5B6560),
    Color(0xFF3D4A33),
    Color(0xFFD8CDB8),
    Color(0xFF9C5A2E),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final c in _swatches)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: const PlaceholderPhoto(
                      icon: Icons.checkroom_outlined,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('NEW ARRIVAL',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 4),
          Text('Nexus Tech Jacket', style: AppTextStyles.cardTitle.copyWith(fontSize: 17)),
          const SizedBox(height: 4),
          Text('Water-resistant fabric with a modern urban fit.',
              style: AppTextStyles.cardSubtitle),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('\$129.00',
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '\$199.00',
                style: AppTextStyles.cardSubtitle.copyWith(
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('35% OFF',
                    style: AppTextStyles.caption.copyWith(color: AppColors.accent)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
