import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../profile_tokens.dart';

/// Prototype `.pf-form-intro`: an `<h2>` heading and `<p>` body used across
/// every profile sub-screen form.
class PfFormIntro extends StatelessWidget {
  const PfFormIntro({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 25, 2, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.dmSans(size: 22, letterSpacing: -.65),
          ),
          const SizedBox(height: 9),
          Text(
            body,
            style: AppTextStyles.dmSans(
              size: 11,
              color: ProfileTokens.introBody,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
