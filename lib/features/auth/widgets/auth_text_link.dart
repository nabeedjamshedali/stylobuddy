import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../auth_tokens.dart';

/// Green bold text link (`.auth-inline button`, `.auth-foot button`,
/// `.auth-secondary-action`).
class AuthTextLink extends StatelessWidget {
  const AuthTextLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: AuthTokens.green,
          ),
        ),
      ),
    );
  }
}

/// `.auth-foot`: grey sentence followed by a [AuthTextLink].
class AuthFoot extends StatelessWidget {
  const AuthFoot({
    super.key,
    required this.text,
    required this.linkLabel,
    required this.onLink,
  });

  final String text;
  final String linkLabel;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          text,
          style: AppTextStyles.dmSans(size: 11.5, color: AuthTokens.foot),
        ),
        AuthTextLink(label: linkLabel, onTap: onLink),
      ],
    );
  }
}
