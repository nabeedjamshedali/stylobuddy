import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../stylist_tokens.dart';

/// Prototype `.notice` banner.
class PrefNotice extends StatelessWidget {
  const PrefNotice(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: StylistTokens.noticeBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: AppTextStyles.dmSans(
        size: 11,
        height: 1.6,
        color: StylistTokens.noticeInk,
      ),
    ),
  );
}
