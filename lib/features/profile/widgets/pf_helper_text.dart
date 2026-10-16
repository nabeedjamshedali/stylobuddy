import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../profile_tokens.dart';

/// Prototype `.pf-helper`: left-aligned 10px disclaimer text.
class PfHelperText extends StatelessWidget {
  const PfHelperText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 18),
      child: Text(
        text,
        style: AppTextStyles.dmSans(
          size: 10,
          color: ProfileTokens.helper,
          height: 1.65,
        ),
      ),
    );
  }
}
