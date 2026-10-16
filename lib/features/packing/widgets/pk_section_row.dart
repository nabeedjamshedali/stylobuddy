import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../packing_tokens.dart';

/// Prototype `.pk-section-title`: bold title with a trailing count, no
/// link (distinct from the shared `SectionTitle`).
class PkSectionRow extends StatelessWidget {
  const PkSectionRow({super.key, required this.title, required this.count});

  final String title;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700),
          ),
          Text(
            count,
            style: AppTextStyles.dmSans(
              size: 10,
              color: PackingTokens.sectionCount,
            ),
          ),
        ],
      ),
    );
  }
}
