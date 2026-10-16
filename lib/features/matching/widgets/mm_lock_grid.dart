import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/garment_image.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../matching_tokens.dart';

/// Prototype `.mm-items` on match-review: 2-column grid of selected items,
/// each marked '◆' (required) or '◇' (candidate).
class MmLockGrid extends StatelessWidget {
  const MmLockGrid({
    super.key,
    required this.ids,
    required this.locked,
    required this.onTap,
  });

  final List<String> ids;
  final Set<String> locked;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeCubit>();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 14),
      itemCount: ids.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (context, i) {
        final id = ids[i];
        final item = wardrobe.itemOrFallback(id);
        final on = locked.contains(id);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(id),
          child: Container(
            padding: on
                ? const EdgeInsets.fromLTRB(5, 5, 5, 11)
                : const EdgeInsets.fromLTRB(6, 6, 6, 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: on ? MatchingTokens.markOn : MatchingTokens.itemBorder,
                width: on ? 2 : 1,
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
                      color: MatchingTokens.imageBg,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(child: GarmentImage(id: item.imageId)),
                        Positioned(
                          top: 7,
                          right: 7,
                          child: Container(
                            width: 23,
                            height: 23,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: on
                                  ? MatchingTokens.markOn
                                  : AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: on
                                    ? MatchingTokens.markOn
                                    : MatchingTokens.markBorder,
                              ),
                            ),
                            child: Text(
                              on ? '◆' : '◇',
                              style: AppTextStyles.dmSans(
                                size: 13,
                                color: on ? AppColors.white : MatchingTokens.markOn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 9, 4, 4),
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.dmSans(
                      size: 11,
                      height: 1.2,
                      color: MatchingTokens.itemInk,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    on ? 'Required in every look' : 'Flexible candidate',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.dmSans(
                      size: 9,
                      color: MatchingTokens.itemSub,
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
