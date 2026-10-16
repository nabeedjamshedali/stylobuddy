import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../profile_tokens.dart';

/// Prototype `.pf-kicker`/`.pf-section-title`: 9px/800/1.4 eyebrow label.
/// `kicker: true` renders the overridden `.pf-kicker` rule used once at the
/// top of the profile page; otherwise `.pf-section-title`.
class PfSectionTitle extends StatelessWidget {
  const PfSectionTitle(this.text, {super.key, this.kicker = false});

  final String text;
  final bool kicker;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: kicker ? 12 : 23, bottom: kicker ? 6 : 11),
      child: Text(
        text,
        style: AppTextStyles.dmSans(
          size: 9,
          weight: FontWeight.w800,
          letterSpacing: 1.4,
          color: kicker ? ProfileTokens.kicker : ProfileTokens.sectionTitle,
        ),
      ),
    );
  }
}
