import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/garment_image.dart';
import '../saved_tokens.dart';

/// Prototype `.sl-garments>button/div`: a saved outfit's piece (tappable, with
/// a category · color subtitle and a chevron) or a wear event's piece
/// (static, category only).
class SlGarmentRow extends StatelessWidget {
  const SlGarmentRow({
    super.key,
    required this.imageId,
    required this.name,
    required this.subtitle,
    this.onTap,
  });

  final String imageId;
  final String name;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        border: Border.all(color: SavedTokens.garmentBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 55,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SavedTokens.garmentPhotoBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: GarmentImage(id: imageId),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: AppTextStyles.dmSans(size: 11)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: SavedTokens.garmentSub,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Text(
              '›',
              style: AppTextStyles.dmSans(
                size: 21,
                color: SavedTokens.garmentChevron,
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: row,
      ),
    );
  }
}
