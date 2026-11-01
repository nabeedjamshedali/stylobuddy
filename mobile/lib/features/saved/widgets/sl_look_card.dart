import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/look_board.dart';
import '../saved_tokens.dart';

/// Prototype `savedLookCard()`: one card in the `.sl-gallery` grid.
class SlLookCard extends StatelessWidget {
  const SlLookCard({
    super.key,
    required this.items,
    required this.name,
    required this.occasion,
    required this.worn,
    required this.onTap,
  });

  final List<String> items;
  final String name;
  final String occasion;
  final int worn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(13),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: SavedTokens.cardBorder),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Container(
                    height: 157,
                    color: SavedTokens.imageBg,
                    padding: const EdgeInsets.all(7),
                    child: LookBoard(
                      ids: items,
                      size: LookBoardSize.third,
                      minHeight: 0,
                      imageHeight: 67,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 7,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '♡',
                        style: AppTextStyles.dmSans(
                          size: 17,
                          color: SavedTokens.heartInk,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$occasion · ${items.length} pieces',
                      style: AppTextStyles.dmSans(
                        size: 9,
                        color: SavedTokens.label,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 34,
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: SavedTokens.footDivider),
                        ),
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$worn times worn',
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.dmSans(
                                size: 9,
                                color: SavedTokens.footMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'View look →',
                            style: AppTextStyles.dmSans(
                              size: 9,
                              weight: FontWeight.w700,
                              color: SavedTokens.footStrong,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
