import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../calendar_tokens.dart';

/// Prototype `.cp-summary`: planned count for the visible month + legend.
class CalendarSummaryRow extends StatelessWidget {
  const CalendarSummaryRow({super.key, required this.plannedCount});

  final int plannedCount;

  @override
  Widget build(BuildContext context) {
    final noun = plannedCount == 1 ? 'look' : 'looks';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              '✧ $plannedCount planned $noun this month',
              style: AppTextStyles.dmSans(
                size: 9,
                color: CalendarTokens.summaryStrong,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '● Planned outfit',
            style: AppTextStyles.dmSans(
              size: 9,
              color: CalendarTokens.summaryMuted,
            ),
          ),
        ],
      ),
    );
  }
}
