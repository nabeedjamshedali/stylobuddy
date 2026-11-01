import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../stylist_tokens.dart';

/// Prototype `.ai-feature` / `.ai-feature-primary` hub button.
class StudioFeatureCard extends StatelessWidget {
  const StudioFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.arrow,
    required this.onTap,
    this.kicker,
    this.primary = false,
  });

  final String icon;
  final String? kicker;
  final String title;
  final String subtitle;
  final String arrow;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final bg = primary ? StylistTokens.featurePrimaryBg : AppColors.white;
    final ink = primary ? AppColors.white : StylistTokens.featureInk;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: primary ? 25 : 10),
        constraints: BoxConstraints(minHeight: primary ? 132 : 81),
        padding: primary
            ? const EdgeInsets.symmetric(horizontal: 15, vertical: 19)
            : const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: primary
                ? StylistTokens.featurePrimaryBg
                : StylistTokens.featureBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 37,
              height: 37,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary
                    ? StylistTokens.featurePrimaryIconBg
                    : StylistTokens.featureIconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                icon,
                style: AppTextStyles.dmSans(
                  size: 22,
                  color: primary
                      ? AppColors.white
                      : StylistTokens.featureIconInk,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kicker != null) ...[
                    Text(
                      kicker!,
                      style: AppTextStyles.dmSans(
                        size: 8,
                        weight: FontWeight.w700,
                        letterSpacing: 1.3,
                        color: StylistTokens.featureSmall,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    title,
                    style: AppTextStyles.dmSans(
                      size: primary ? 20 : 15,
                      weight: FontWeight.w700,
                      height: 1.25,
                      letterSpacing: -.25,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: AppTextStyles.dmSans(
                      size: 10,
                      height: 1.5,
                      color: primary
                          ? StylistTokens.featurePrimarySub
                          : StylistTokens.featureSub,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              arrow,
              style: AppTextStyles.dmSans(
                size: 20,
                color: primary ? AppColors.white : StylistTokens.featureArrow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
