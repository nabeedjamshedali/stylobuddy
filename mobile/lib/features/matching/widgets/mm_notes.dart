import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../matching_tokens.dart';

/// Prototype `.mm-lock-legend`: "Required" / "Candidate" dot legend.
class MmLockLegend extends StatelessWidget {
  const MmLockLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.dmSans(size: 10, color: MatchingTokens.legendInk);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const _Dot(locked: true),
          const SizedBox(width: 5),
          Text('Required', style: style),
          const SizedBox(width: 16),
          const _Dot(locked: false),
          const SizedBox(width: 5),
          Text('Candidate', style: style),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: locked ? MatchingTokens.markOn : null,
        border: Border.all(
          color: locked ? MatchingTokens.markOn : MatchingTokens.dotBorder,
        ),
      ),
    );
  }
}

/// Prototype `.mm-note`: pale green note box with a bold headline.
class MmNote extends StatelessWidget {
  const MmNote({super.key, required this.headline, required this.body});

  final String headline;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MatchingTokens.noteBg,
        border: Border.all(color: MatchingTokens.noteBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppTextStyles.dmSans(size: 11, height: 1.6),
          ),
        ],
      ),
    );
  }
}

/// Prototype `.notice.warning`.
class MmWarningNotice extends StatelessWidget {
  const MmWarningNotice(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MatchingTokens.warningBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTextStyles.dmSans(
          size: 11,
          height: 1.6,
          color: MatchingTokens.warningInk,
        ),
      ),
    );
  }
}
