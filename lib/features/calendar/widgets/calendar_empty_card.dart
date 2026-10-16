import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../calendar_tokens.dart';

/// Prototype `.cp-empty`: dashed card for 'No outfit planned yet' and the
/// chooser's 'No saved outfits yet' state.
class CalendarEmptyCard extends StatelessWidget {
  const CalendarEmptyCard({
    super.key,
    required this.title,
    required this.body,
    this.icon = '▦',
  });

  final String title;
  final String body;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
      decoration: BoxDecoration(
        color: CalendarTokens.emptyBg,
        border: Border.all(color: CalendarTokens.emptyBorder, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: AppTextStyles.dmSans(
              size: 25,
              color: CalendarTokens.emptyIcon,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 10,
              color: CalendarTokens.emptyBody,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
