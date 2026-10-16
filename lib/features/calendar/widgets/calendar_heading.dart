import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../calendar_tokens.dart';

/// Prototype `.cp-eyebrow` + `h2` + `.cp-subtitle`: reused by `/calendar`,
/// `/calendar-choose` and `/calendar-date`.
class CalendarHeading extends StatelessWidget {
  const CalendarHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: AppTextStyles.dmSans(
            size: 9,
            weight: FontWeight.w800,
            letterSpacing: 1.7,
            color: CalendarTokens.eyebrow,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          style: AppTextStyles.manrope(
            size: 24,
            weight: FontWeight.w700,
            letterSpacing: -0.9,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTextStyles.dmSans(
            size: 11,
            color: CalendarTokens.subtitle,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
