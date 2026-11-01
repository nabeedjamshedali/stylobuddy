import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../insights_tokens.dart';

/// Prototype `insightTitle(title, caption)`, `P/app.js:328`: a bold title
/// with a small caption on the right, no link affordance.
class InSectionHead extends StatelessWidget {
  const InSectionHead({super.key, required this.title, this.caption});

  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(width: 8),
            Text(
              caption!,
              style: AppTextStyles.dmSans(
                size: 10,
                color: InsightsTokens.sectionCaption,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
