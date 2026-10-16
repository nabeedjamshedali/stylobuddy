import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/garment_image.dart';
import '../saved_tokens.dart';

/// Prototype `wearCard()`: one row in the `.sl-timeline`.
class SlWearCard extends StatelessWidget {
  const SlWearCard({
    super.key,
    required this.firstItemId,
    required this.timestamp,
    required this.name,
    required this.occasion,
    required this.pieceCount,
    required this.onTap,
  });

  final String firstItemId;
  final DateTime timestamp;
  final String name;
  final String occasion;
  final int pieceCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            border: Border.all(color: SavedTokens.entryBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 65,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SavedTokens.thumbBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FractionallySizedBox(
                  widthFactor: .9,
                  heightFactor: .9,
                  child: GarmentImage(id: firstItemId),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM d, y').format(timestamp),
                      style: AppTextStyles.dmSans(
                        size: 9,
                        weight: FontWeight.w700,
                        color: SavedTokens.dateInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(name, style: AppTextStyles.dmSans(size: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '$pieceCount pieces · $occasion',
                      style: AppTextStyles.dmSans(
                        size: 10,
                        color: SavedTokens.entrySub,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '›',
                style: AppTextStyles.dmSans(size: 22, color: SavedTokens.chevron),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
