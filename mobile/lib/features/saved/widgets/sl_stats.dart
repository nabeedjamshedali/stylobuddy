import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../saved_tokens.dart';

/// Prototype `.sl-stats`: three stat boxes (Saved outfits / Wears logged /
/// Worn looks).
class SlStats extends StatelessWidget {
  const SlStats({
    super.key,
    required this.saved,
    required this.wearsLogged,
    required this.wornLooks,
  });

  final int saved;
  final int wearsLogged;
  final int wornLooks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat(value: '$saved', label: 'Saved outfits')),
        const SizedBox(width: 8),
        Expanded(child: _Stat(value: '$wearsLogged', label: 'Wears logged')),
        const SizedBox(width: 8),
        Expanded(child: _Stat(value: '$wornLooks', label: 'Worn looks')),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 7),
      decoration: BoxDecoration(
        color: SavedTokens.statBg,
        border: Border.all(color: SavedTokens.statBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 18,
              weight: FontWeight.w700,
              color: SavedTokens.statValue,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(size: 9, color: SavedTokens.statLabel),
          ),
        ],
      ),
    );
  }
}
