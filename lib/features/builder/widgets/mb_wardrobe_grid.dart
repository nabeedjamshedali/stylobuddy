import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/garment_image.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../builder_tokens.dart';

/// Prototype `.mb-wardrobe-grid`: 2-column tile grid, each tile toggling
/// between the `+` and `✓` mark.
class MbWardrobeGrid extends StatelessWidget {
  const MbWardrobeGrid({
    super.key,
    required this.ids,
    required this.picked,
    required this.onTap,
  });

  final List<String> ids;
  final Set<String> picked;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeCubit>();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 17),
      itemCount: ids.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 11,
        mainAxisSpacing: 11,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, i) {
        final id = ids[i];
        final item = wardrobe.itemOrFallback(id);
        final selected = picked.contains(id);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(id),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: selected ? BuilderTokens.itemSelectedBg : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? BuilderTokens.itemSelectedBorder
                    : BuilderTokens.itemBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: BuilderTokens.itemPhotoBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(child: GarmentImage(id: item.imageId)),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? BuilderTokens.itemCheckInk
                                  : AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: BuilderTokens.itemCheckBorder,
                              ),
                            ),
                            child: Text(
                              selected ? '✓' : '+',
                              style: AppTextStyles.dmSans(
                                size: 14,
                                color: selected
                                    ? AppColors.white
                                    : BuilderTokens.itemCheckInk,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(3, 9, 3, 4),
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    '${item.category} · ${item.color}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.dmSans(
                      size: 9,
                      color: BuilderTokens.itemSub,
                    ),
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
