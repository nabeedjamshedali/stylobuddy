import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/clothing_item.dart';
import '../wardrobe_tokens.dart';

/// Prototype `wardrobeStats()`: Pieces / Categories / Worn pieces.
class WardrobeStats extends StatelessWidget {
  const WardrobeStats({super.key, required this.items});

  final List<ClothingItem> items;

  @override
  Widget build(BuildContext context) {
    final categories = items.map((i) => i.category).toSet();
    final worn = items.where((i) => i.wears > 0).length;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: WardrobeTokens.statBorder),
        borderRadius: BorderRadius.circular(13),
        color: WardrobeTokens.statBg,
      ),
      child: Row(
        children: [
          _Stat(value: '${items.length}', label: 'Pieces', last: false),
          _Stat(value: '${categories.length}', label: 'Categories', last: false),
          _Stat(value: '$worn', label: 'Worn pieces', last: true),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.last});

  final String value;
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 3),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  right: BorderSide(color: WardrobeTokens.statBorder),
                ),
        ),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans(
                size: 21,
                weight: FontWeight.w700,
                color: WardrobeTokens.statValue,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans(
                size: 9.5,
                color: WardrobeTokens.statLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
