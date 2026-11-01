import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/garment_image.dart';
import '../wardrobe_tokens.dart';

/// Prototype `wardrobeGrid()`: the 3-column tile grid, tile is
/// `wardrobeProduct()`.
class WardrobeGrid extends StatelessWidget {
  const WardrobeGrid({super.key, required this.items, required this.onTap});

  final List<ClothingItem> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 9,
        mainAxisSpacing: 14,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return _Tile(item: item, onTap: () => onTap(item.id));
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.onTap});

  final ClothingItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 0.91,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: WardrobeTokens.tilePhotoBg,
                      border: Border.all(color: WardrobeTokens.tilePhotoBorder),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: GarmentImage(id: item.imageId),
                  ),
                ),
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    width: 19,
                    height: 19,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: WardrobeTokens.tileIconBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '↗',
                      style: AppTextStyles.dmSans(
                        size: 10,
                        color: WardrobeTokens.tileIconInk,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            '${item.color} · ${item.category}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.dmSans(size: 9, color: WardrobeTokens.tileSub),
          ),
        ],
      ),
    );
  }
}

/// Prototype `wardrobeGrid()`'s `.w-empty` branch: search vs. plain-category
/// empty copy, with the matching recovery action.
class WardrobeEmptyState extends StatelessWidget {
  const WardrobeEmptyState({
    super.key,
    required this.searching,
    required this.onAction,
  });

  final bool searching;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 38),
      decoration: BoxDecoration(
        border: Border.all(color: WardrobeTokens.emptyBorder, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            '♧',
            style: AppTextStyles.dmSans(size: 32, color: WardrobeTokens.emptyIcon),
          ),
          const SizedBox(height: 13),
          Text(
            'Nothing here yet',
            style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            searching
                ? 'Try a different search, or clear the search field.'
                : 'This category is waiting for your first item.',
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 11,
              color: WardrobeTokens.emptyBody,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: searching ? 'Clear search' : 'Add clothing',
            onPressed: onAction,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
