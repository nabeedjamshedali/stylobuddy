import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/garment_image.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../builder_tokens.dart';

/// Prototype `.mb-preview`: live composition (first 6 picked garments, each
/// with a remove `×`), the empty placeholder, and the full `.mb-selected-
/// tags` row (every picked piece, even past the first 6).
class MbLivePreview extends StatelessWidget {
  const MbLivePreview({
    super.key,
    required this.picked,
    required this.onRemove,
  });

  final List<String> picked;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeCubit>();
    final count = picked.length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BuilderTokens.previewBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: BuilderTokens.previewBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Live outfit preview',
                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '$count ${count == 1 ? 'item' : 'items'}',
                style: AppTextStyles.dmSans(
                  size: 10,
                  color: BuilderTokens.previewCount,
                ),
              ),
            ],
          ),
          if (picked.isEmpty)
            const _EmptyPreview()
          else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: picked.length > 6 ? 6 : picked.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 7,
                  mainAxisSpacing: 7,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, i) {
                  final id = picked[i];
                  final item = wardrobe.itemOrFallback(id);
                  return _Garment(
                    imageId: item.imageId,
                    onRemove: () => onRemove(id),
                    removeLabel: 'Remove ${item.name}',
                  );
                },
              ),
            ),
          if (picked.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (final id in picked)
                    _Tag(
                      label: wardrobe.itemOrFallback(id).name,
                      onTap: () => onRemove(id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            '✧',
            style: AppTextStyles.dmSans(size: 26, color: BuilderTokens.emptyIcon),
          ),
          const SizedBox(height: 7),
          Text(
            'Your look starts here',
            style: AppTextStyles.dmSans(
              size: 12,
              weight: FontWeight.w700,
              color: BuilderTokens.emptyTitle,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Select clothing below to build an outfit.',
            style: AppTextStyles.dmSans(
              size: 10,
              color: BuilderTokens.emptyBody,
            ),
          ),
        ],
      ),
    );
  }
}

class _Garment extends StatelessWidget {
  const _Garment({
    required this.imageId,
    required this.onRemove,
    required this.removeLabel,
  });

  final String imageId;
  final VoidCallback onRemove;
  final String removeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(11),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: GarmentImage(id: imageId)),
          Positioned(
            right: 4,
            top: 4,
            child: Material(
              color: AppColors.white,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: BuilderTokens.previewButtonShadow,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: SizedBox(
                  width: 21,
                  height: 21,
                  child: Center(
                    child: Semantics(
                      label: removeLabel,
                      child: Text(
                        '×',
                        style: AppTextStyles.dmSans(size: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
        side: const BorderSide(color: BuilderTokens.tagBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(
            '$label ×',
            style: AppTextStyles.dmSans(size: 9, color: BuilderTokens.tagInk),
          ),
        ),
      ),
    );
  }
}
