import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/garment_image.dart';
import '../../../shared/models/clothing_item.dart';
import '../packing_tokens.dart';

/// Prototype `.pk-add-grid` / `.pk-add-card`: 2-column grid of wardrobe
/// items; already-added items show 'Added' and are disabled.
class PkAddGrid extends StatelessWidget {
  const PkAddGrid({
    super.key,
    required this.items,
    required this.addedIds,
    required this.onAdd,
  });

  final List<ClothingItem> items;
  final Set<String> addedIds;
  final ValueChanged<ClothingItem> onAdd;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        final added = addedIds.contains(item.id);
        return Opacity(
          opacity: added ? 0.55 : 1,
          child: Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: added ? null : () => onAdd(item),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: PackingTokens.addCardBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: AppColors.productBg,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: GarmentImage(id: item.imageId),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700),
                    ),
                    Text(
                      added ? 'Added' : '＋ Add',
                      style: AppTextStyles.dmSans(
                        size: 10,
                        color: PackingTokens.addCardEm,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
