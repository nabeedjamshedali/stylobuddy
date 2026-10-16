import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/wardrobe/cubit/wardrobe_cubit.dart';
import 'garment_image.dart';
import 'shared_tokens.dart';

/// Prototype `tiles()`: 3-column grid of product tiles with select tick and
/// optional lock badge.
class ItemTileGrid extends StatelessWidget {
  const ItemTileGrid({
    super.key,
    required this.ids,
    required this.selected,
    this.locked = const {},
    required this.onTap,
    this.showLock = false,
  });

  final List<String> ids;
  final Set<String> selected;
  final Set<String> locked;
  final ValueChanged<String> onTap;
  final bool showLock;

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeCubit>();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: ids.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        // square image + name (10px) + category (9px) block
        childAspectRatio: 0.74,
      ),
      itemBuilder: (context, i) {
        final id = ids[i];
        final item = wardrobe.itemOrFallback(id);
        return _Tile(
          imageId: item.imageId,
          name: item.name,
          category: item.category,
          selected: selected.contains(id),
          locked: showLock && locked.contains(id),
          onTap: () => onTap(id),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.imageId,
    required this.name,
    required this.category,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final String imageId;
  final String name;
  final String category;
  final bool selected;
  final bool locked;
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
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? SharedTokens.tileSelectedBg
                          : AppColors.productBg,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: selected
                            ? AppColors.green
                            : SharedTokens.tileBorder,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: GarmentImage(id: imageId),
                  ),
                ),
                if (selected)
                  const Positioned(top: 7, right: 7, child: _Badge('✓')),
                if (locked)
                  const Positioned(
                    top: 7,
                    left: 7,
                    child: _Badge('🔒', color: SharedTokens.tileLock),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.dmSans(size: 9, color: SharedTokens.tileSub),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.glyph, {this.color = AppColors.green});

  final String glyph;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(glyph,
          style: AppTextStyles.dmSans(size: 12, color: AppColors.white)),
    );
  }
}
