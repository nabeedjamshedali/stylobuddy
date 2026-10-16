import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../profile_tokens.dart';

/// Prototype `.pf-warning`.
class PfWarningBox extends StatelessWidget {
  const PfWarningBox(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 17),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProfileTokens.warningBg,
        border: Border.all(color: ProfileTokens.warningBorder),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        text,
        style: AppTextStyles.dmSans(
          size: 11,
          color: ProfileTokens.warningInk,
          height: 1.65,
        ),
      ),
    );
  }
}
