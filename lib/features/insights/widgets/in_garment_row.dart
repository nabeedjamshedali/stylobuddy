import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/garment_image.dart';
import '../insights_tokens.dart';

/// Prototype `insightMiniGarment(it, subtitle)`, `P/app.js:329`.
class InGarmentRow extends StatelessWidget {
  const InGarmentRow({
    super.key,
    required this.itemId,
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  final String itemId;
  final String name;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: InsightsTokens.garmentBorder),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: InsightsTokens.garmentThumbBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GarmentImage(id: itemId),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: AppTextStyles.dmSans(size: 11)),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: AppTextStyles.dmSans(
                        size: 10,
                        color: InsightsTokens.garmentSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '›',
                  style: AppTextStyles.dmSans(size: 20, color: InsightsTokens.garmentChevron),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
