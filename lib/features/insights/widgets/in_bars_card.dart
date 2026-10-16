import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../insights_tokens.dart';

/// Prototype `.in-card.in-bars`: one bar per category, widest bar is the
/// largest count (100%), others are `count/maxCat*100`.
class InBarsCard extends StatelessWidget {
  const InBarsCard({super.key, required this.cats});

  final List<(String, int)> cats;

  @override
  Widget build(BuildContext context) {
    final maxCat = cats.isEmpty ? 1 : cats.map((c) => c.$2).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: InsightsTokens.cardBorder),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          for (var i = 0; i < cats.length; i++) ...[
            if (i > 0) const SizedBox(height: 13),
            _BarRow(
              label: cats[i].$1,
              count: cats[i].$2,
              fraction: cats[i].$2 / maxCat,
              color: InsightsTokens.palette[i % InsightsTokens.palette.length],
            ),
          ],
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.count,
    required this.fraction,
    required this.color,
  });

  final String label;
  final int count;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 10, color: InsightsTokens.barLabel)),
            Text(
              '$count',
              style: AppTextStyles.dmSans(
                size: 10,
                weight: FontWeight.w700,
                color: InsightsTokens.barCount,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 7,
            child: ColoredBox(
              color: InsightsTokens.barTrack,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
