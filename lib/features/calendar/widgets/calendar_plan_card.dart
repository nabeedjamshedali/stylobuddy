import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/look_board.dart';
import '../calendar_tokens.dart';

/// Prototype `.cp-plan-card`: the planned look (tappable to view the outfit
/// when [onTap] is given, `.static` i.e. non-tappable otherwise).
class CalendarPlanCard extends StatelessWidget {
  const CalendarPlanCard({
    super.key,
    required this.items,
    required this.name,
    required this.subtitle,
    this.onTap,
    this.eyebrow = 'YOUR PLANNED LOOK',
  });

  final List<String> items;
  final String name;
  final String subtitle;
  final VoidCallback? onTap;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      constraints: const BoxConstraints(minHeight: 117),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: CalendarTokens.planCardBorder),
        borderRadius: BorderRadius.circular(13),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                color: CalendarTokens.planImageBg,
                padding: const EdgeInsets.all(7),
                child: LookBoard(
                  ids: items,
                  size: LookBoardSize.third,
                  columns: 2,
                  minHeight: 98,
                  imageHeight: 46,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      eyebrow,
                      style: AppTextStyles.dmSans(
                        size: 8,
                        weight: FontWeight.w700,
                        letterSpacing: .9,
                        color: CalendarTokens.planLabel,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: AppTextStyles.dmSans(
                        size: 10,
                        color: CalendarTokens.planSub,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'View outfit ↗',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.w700,
                          color: CalendarTokens.planLink,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}
