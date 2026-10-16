import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/garment_image.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../models/packing_item.dart';
import '../packing_tokens.dart';

/// Prototype `.pk-checklist` / `.pk-check`: a packing row with a checkbox,
/// thumbnail (or a `✧` placeholder for custom essentials) and a remove `×`.
class PkChecklist extends StatelessWidget {
  const PkChecklist({
    super.key,
    required this.items,
    required this.onToggle,
    required this.onRemove,
  });

  final List<PackingItem> items;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeCubit>();
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _Row(
              item: item,
              imageId: item.wardrobeId == null
                  ? null
                  : wardrobe.itemOrFallback(item.wardrobeId!).imageId,
              onToggle: () => onToggle(item.key),
              onRemove: () => onRemove(item.key),
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.item,
    required this.imageId,
    required this.onToggle,
    required this.onRemove,
  });

  final PackingItem item;
  final String? imageId;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: PackingTokens.checkBorder),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.packed,
            activeColor: PackingTokens.checkAccent,
            onChanged: (_) => onToggle(),
          ),
          Container(
            width: 40,
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PackingTokens.thumbBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: imageId == null
                ? Text(
                    '✧',
                    style: AppTextStyles.dmSans(size: 16, color: AppColors.muted),
                  )
                : GarmentImage(id: imageId!),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: item.packed ? PackingTokens.doneInk : null,
                height: item.packed ? null : null,
              ).copyWith(
                decoration:
                    item.packed ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                '×',
                style: AppTextStyles.dmSans(
                  size: 20,
                  color: PackingTokens.removeGlyph,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
