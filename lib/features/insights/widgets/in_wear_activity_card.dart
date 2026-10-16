import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../insights_tokens.dart';
import '../models/insight_stats.dart';

/// Prototype `.in-card` block under 'Wear activity': worn/total, a progress
/// bar, the unused-items note and the 'View wear history →' link.
class InWearActivityCard extends StatelessWidget {
  const InWearActivityCard({
    super.key,
    required this.worn,
    required this.count,
    required this.unused,
    required this.onViewHistory,
  });

  final int worn;
  final int count;
  final int unused;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final percent = InsightStats.percent(worn, count) / 100;
    final verb = unused == 1 ? ' has' : 's have';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: InsightsTokens.cardBorder),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$worn',
                style: AppTextStyles.dmSans(
                  size: 25,
                  weight: FontWeight.w700,
                  color: InsightsTokens.wearValue,
                ),
              ),
              Text(
                ' / $count',
                style: AppTextStyles.dmSans(size: 14, color: InsightsTokens.wearTotal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'pieces with recorded wears',
                  style: AppTextStyles.dmSans(size: 11, color: InsightsTokens.wearCaption),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: SizedBox(
              height: 7,
              child: ColoredBox(
                color: InsightsTokens.progressTrack,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: percent.clamp(0.0, 1.0),
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: InsightsTokens.progressFill,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$unused item$verb no recorded wears. This uses the demo’s item '
            'wear counters; it is not a prediction of how often you actually '
            'dress in each piece.',
            style: AppTextStyles.dmSans(size: 10.5, height: 1.6, color: InsightsTokens.note),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onViewHistory,
              child: Text(
                'View wear history →',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w700,
                  color: InsightsTokens.textButton,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
