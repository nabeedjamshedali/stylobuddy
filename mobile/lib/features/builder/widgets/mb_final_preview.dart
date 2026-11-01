import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/garment_image.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../builder_tokens.dart';

/// Prototype `.mb-final-preview`: every picked garment (no remove control),
/// or the plain 'No garments chosen yet' message.
class MbFinalPreview extends StatelessWidget {
  const MbFinalPreview({super.key, required this.picked});

  final List<String> picked;

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeCubit>();
    return Container(
      margin: const EdgeInsets.only(bottom: 17),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BuilderTokens.previewBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: BuilderTokens.previewBorder),
      ),
      child: picked.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 45),
                child: Text(
                  'No garments chosen yet',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    color: BuilderTokens.emptyBody,
                  ),
                ),
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: picked.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 7,
                mainAxisSpacing: 7,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, i) {
                final item = wardrobe.itemOrFallback(picked[i]);
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: GarmentImage(id: item.imageId),
                );
              },
            ),
    );
  }
}
