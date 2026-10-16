import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/garment_image.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../models/packing_item.dart';
import '../packing_tokens.dart';

/// Prototype `.pk-items-preview`: 3-column grid of suggested pieces.
class PkPreviewGrid extends StatelessWidget {
  const PkPreviewGrid({super.key, required this.items});

  final List<PackingItem> items;

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeCubit>();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.74,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        final imageId = item.wardrobeId == null
            ? null
            : wardrobe.itemOrFallback(item.wardrobeId!).imageId;
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: PackingTokens.previewBg,
            borderRadius: BorderRadius.all(Radius.circular(9)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: imageId == null
                      ? const ColoredBox(color: AppColors.productBg)
                      : GarmentImage(id: imageId),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.dmSans(size: 9),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
