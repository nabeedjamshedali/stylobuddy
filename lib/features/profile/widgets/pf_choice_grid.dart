import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../profile_tokens.dart';

/// Prototype `.pf-select-grid` + `.pf-choice`: a 2-column grid of toggle
/// chips showing `✓`/`＋`, used by edit-style and the fallback-climate picker
/// (`P/app.js:275`, `279`).
class PfChoiceGrid extends StatelessWidget {
  const PfChoiceGrid({
    super.key,
    required this.options,
    required this.isSelected,
    required this.onTap,
  });

  final List<String> options;
  final bool Function(String option) isSelected;
  final void Function(String option) onTap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += 2) {
      final left = options[i];
      final right = i + 1 < options.length ? options[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < options.length ? 9 : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _tile(left)),
                if (right != null) ...[
                  const SizedBox(width: 9),
                  Expanded(child: _tile(right)),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }

  Widget _tile(String option) {
    final selected = isSelected(option);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(option),
      child: Container(
        constraints: const BoxConstraints(minHeight: 49),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? ProfileTokens.choiceSelectedBg : AppColors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected
                ? ProfileTokens.choiceSelectedBorder
                : ProfileTokens.choiceBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                option,
                style: AppTextStyles.dmSans(
                  size: 11,
                  color: selected
                      ? ProfileTokens.choiceSelectedInk
                      : ProfileTokens.choiceInk,
                ),
              ),
            ),
            Text(
              selected ? '✓' : '＋',
              style: AppTextStyles.dmSans(
                size: 11,
                color: selected
                    ? ProfileTokens.choiceSelectedMarker
                    : ProfileTokens.choiceMarker,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
