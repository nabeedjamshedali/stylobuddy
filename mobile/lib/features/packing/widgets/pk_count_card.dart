import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../packing_tokens.dart';
import 'pk_progress_bar.dart';

/// Prototype `.pk-count` + `.pk-progress`: the "N% packed" header with the
/// progress bar underneath.
class PkCountCard extends StatelessWidget {
  const PkCountCard({
    super.key,
    required this.percent,
    required this.packed,
    required this.total,
  });

  final int percent;
  final int packed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PackingTokens.countBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$percent% packed',
                    style: AppTextStyles.dmSans(
                      size: 16,
                      weight: FontWeight.w700,
                      color: PackingTokens.countInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$packed of $total items ready',
                    style: AppTextStyles.dmSans(
                      size: 10,
                      color: PackingTokens.countInk,
                    ),
                  ),
                ],
              ),
              Text(
                percent == 100 ? '✓' : '✧',
                style: AppTextStyles.dmSans(
                  size: 18,
                  color: PackingTokens.countInk,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        PkProgressBar(value: total == 0 ? 0 : percent / 100, height: 7),
      ],
    );
  }
}
