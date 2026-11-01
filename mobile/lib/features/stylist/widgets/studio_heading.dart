import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../stylist_tokens.dart';

/// Small bold heading used on the hub (`.ai-mini-heading`, `.ai-section-title`).
class StudioHeading extends StatelessWidget {
  const StudioHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Text(
      text,
      style: AppTextStyles.dmSans(
        size: 12,
        weight: FontWeight.w700,
        color: StylistTokens.miniHeading,
      ),
    ),
  );
}

/// `.ai-overline` eyebrow.
class StudioOverline extends StatelessWidget {
  const StudioOverline(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Text(
      text,
      style: AppTextStyles.dmSans(
        size: 9,
        weight: FontWeight.w800,
        letterSpacing: 1.65,
        color: StylistTokens.overline,
      ),
    ),
  );
}
