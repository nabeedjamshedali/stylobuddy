import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/demo_note.dart';
import '../../../shared/widgets/garment_image.dart';
import '../../../shared/widgets/screen_head.dart';
import '../cubit/import_cubit.dart';
import '../wardrobe_tokens.dart';

/// Prototype `pages.batch`: review the batch before simulated analysis.
class BatchView extends StatelessWidget {
  const BatchView({super.key});

  @override
  Widget build(BuildContext context) {
    final drafts = context.watch<ImportCubit>().state.drafts;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Review Photos',
            fallbackRoute: AppRoutes.importSource,
          ),
          Text(
            'STEP 1 OF 3',
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w800,
              letterSpacing: 1.35,
              color: WardrobeTokens.eyebrow,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Ready to organize?',
            style: AppTextStyles.manrope(
              size: 23,
              weight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We’ll prepare clean product images and suggest category, '
            'color, season and occasion for each garment.',
            style: AppTextStyles.dmSans(size: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: drafts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1 / 0.85,
            ),
            itemBuilder: (context, i) => _SampleTile(id: drafts[i].imageId),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 25),
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: WardrobeTokens.summaryBorder),
                bottom: BorderSide(color: WardrobeTokens.summaryBorder),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${drafts.length} items',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    color: WardrobeTokens.summaryInk,
                  ),
                ),
                Text(
                  'Ready for AI analysis',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w700,
                    color: WardrobeTokens.summaryStrong,
                  ),
                ),
              ],
            ),
          ),
          PrimaryButton(
            label: '✧ Analyze clothing',
            onPressed: () => context.push(AppRoutes.analyzing),
          ),
          const DemoNote('AI processing is simulated in this prototype.'),
        ],
      ),
    );
  }
}

class _SampleTile extends StatelessWidget {
  const _SampleTile({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: WardrobeTokens.sampleGridBg,
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: GarmentImage(id: id),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 17,
            height: 17,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: WardrobeTokens.addBg,
              shape: BoxShape.circle,
            ),
            child: Text(
              '✓',
              style: AppTextStyles.dmSans(size: 10, color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }
}
