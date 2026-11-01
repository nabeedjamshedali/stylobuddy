import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../profile_tokens.dart';

/// Prototype `.pf-empty`: icon + heading + body, used by support-detail,
/// signout and purchase.
class PfEmptyState extends StatelessWidget {
  const PfEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 45),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 38, color: ProfileTokens.emptyIcon)),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.dmSans(size: 18)),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 11,
              color: ProfileTokens.emptyBody,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
