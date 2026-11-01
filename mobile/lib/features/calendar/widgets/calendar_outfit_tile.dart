import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/look_board.dart';
import '../calendar_tokens.dart';

/// Prototype `.cp-outfit-list > button`: one saved outfit on
/// `/calendar-choose`.
class CalendarOutfitTile extends StatelessWidget {
  const CalendarOutfitTile({
    super.key,
    required this.items,
    required this.name,
    required this.occasion,
    required this.pieceCount,
    required this.onTap,
  });

  final List<String> items;
  final String name;
  final String occasion;
  final int pieceCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: CalendarTokens.outfitRowBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 74,
                    color: CalendarTokens.thumbnailBg,
                    padding: const EdgeInsets.all(4),
                    child: LookBoard(
                      ids: items,
                      size: LookBoardSize.third,
                      columns: 2,
                      minHeight: 0,
                      imageHeight: 30,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$occasion · $pieceCount pieces',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          color: CalendarTokens.outfitName,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '›',
                  style: AppTextStyles.dmSans(
                    size: 22,
                    color: CalendarTokens.outfitChevron,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
