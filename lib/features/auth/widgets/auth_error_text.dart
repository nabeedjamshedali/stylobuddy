import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../auth_tokens.dart';

/// `.auth-error`: inline form error; renders nothing while [message] is null.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AuthTokens.errorBg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: AppTextStyles.dmSans(size: 11, color: AuthTokens.errorInk),
      ),
    );
  }
}
