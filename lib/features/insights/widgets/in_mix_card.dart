import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../insights_tokens.dart';
import '../models/insight_stats.dart';
import 'in_donut.dart';

/// Prototype `.in-card .in-mix`: donut chart plus a percentage legend,
/// `d.cats` percentages via `insightPercent`.
class InMixCard extends StatelessWidget {
  const InMixCard({super.key, required this.cats, required this.count});

  final List<(String, int)> cats;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: InsightsTokens.cardBorder),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InDonut(cats: cats, total: count),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < cats.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _LegendRow(
                    color: InsightsTokens.palette[i % InsightsTokens.palette.length],
                    label: cats[i].$1,
                    percent: InsightStats.percent(cats[i].$2, count),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, required this.percent});

  final Color color;
  final String label;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.dmSans(size: 10, color: InsightsTokens.legendLabel),
          ),
        ),
        Text(
          '$percent%',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.w700,
            color: InsightsTokens.legendValue,
          ),
        ),
      ],
    );
  }
}
