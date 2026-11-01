import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../stylist_tokens.dart';
import 'studio_heading.dart';

/// Overline, headline, sub-copy and (match mode) context line of `.ai-results`.
class ResultsHeader extends StatelessWidget {
  const ResultsHeader({
    super.key,
    required this.count,
    required this.occasion,
    this.contextLine,
  });

  final int count;
  final String occasion;

  /// Match mode only: "N locked must-wear items · M selected candidates".
  final String? contextLine;

  String get _headline => count == 3
      ? 'Three looks, made for you'
      : '$count look${count == 1 ? '' : 's'} from your selection';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 11),
        const StudioOverline('YOUR PERSONAL STYLE EDIT'),
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Text(
            _headline,
            style: AppTextStyles.manrope(
              size: 23,
              height: 1.2,
              letterSpacing: -.65,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 23),
          child: Text(
            'Real pieces in your wardrobe, thoughtfully put together for ${occasion.toLowerCase()}.',
            style: AppTextStyles.dmSans(
              size: 12,
              height: 1.65,
              color: StylistTokens.lead,
            ),
          ),
        ),
        if (contextLine != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: StylistTokens.contextBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              contextLine!,
              style: AppTextStyles.dmSans(
                size: 10,
                color: StylistTokens.contextInk,
              ),
            ),
          ),
      ],
    );
  }
}
