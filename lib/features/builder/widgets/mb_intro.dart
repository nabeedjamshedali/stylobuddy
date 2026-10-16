import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../builder_tokens.dart';

/// Prototype `.mb-intro`: kicker, headline and description, left aligned.
class MbIntro extends StatelessWidget {
  const MbIntro({
    super.key,
    required this.kicker,
    required this.title,
    required this.body,
  });

  final String kicker;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w800,
              letterSpacing: 1.4,
              color: BuilderTokens.kicker,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              title,
              style: AppTextStyles.manrope(
                size: 21,
                height: 1.25,
                letterSpacing: -.8,
              ),
            ),
          ),
          Text(
            body,
            style: AppTextStyles.dmSans(
              size: 11,
              height: 1.6,
              color: BuilderTokens.introBody,
            ),
          ),
        ],
      ),
    );
  }
}
