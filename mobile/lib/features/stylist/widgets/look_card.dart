import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/look_board.dart';
import '../models/style_result.dart';
import '../stylist_tokens.dart';

/// Prototype `.ai-look` card on the results screen.
class LookCard extends StatelessWidget {
  const LookCard({
    super.key,
    required this.result,
    required this.index,
    required this.total,
    required this.onTap,
  });

  final StyleResult result;
  final int index;
  final int total;
  final VoidCallback onTap;

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: StylistTokens.lookBorder),
          boxShadow: const [
            BoxShadow(
              color: StylistTokens.lookShadow,
              blurRadius: 22,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: StylistTokens.lookBoardBg,
              padding: const EdgeInsets.all(7),
              child: LookBoard(
                ids: result.items,
                size: LookBoardSize.third,
                minHeight: 170,
                imageHeight: 124,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LOOK ${_pad(index + 1)} / ${_pad(total)}',
                    style: AppTextStyles.dmSans(
                      size: 9,
                      weight: FontWeight.w800,
                      letterSpacing: 1.35,
                      color: StylistTokens.lookIndex,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.name,
                    style: AppTextStyles.dmSans(
                      size: 17,
                      weight: FontWeight.w700,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.why,
                    style: AppTextStyles.dmSans(
                      size: 11,
                      height: 1.6,
                      color: StylistTokens.lookWhy,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    'Explore this outfit →',
                    style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: StylistTokens.lookExplore,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
