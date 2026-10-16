import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/garment_image.dart';
import '../../../shared/widgets/screen_head.dart';
import '../cubit/import_cubit.dart';
import '../wardrobe_tokens.dart';

/// Prototype `pages['import-source']`.
class ImportSourceView extends StatelessWidget {
  const ImportSourceView({super.key});

  static const counts = [1, 3, 6];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ImportCubit>();
    final state = context.watch<ImportCubit>().state;
    final pool = ImportCubit.pool.take(state.count).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Choose Photos',
            fallbackRoute: AppRoutes.import,
          ),
          Text(
            state.source == 'camera' ? 'CAMERA IMPORT' : 'GALLERY IMPORT',
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w800,
              letterSpacing: 1.35,
              color: WardrobeTokens.eyebrow,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Select your pieces',
            style: AppTextStyles.manrope(
              size: 23,
              weight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a sample batch to walk through the complete '
            'clothing-import experience.',
            style: AppTextStyles.dmSans(size: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (var i = 0; i < counts.length; i++) ...[
                if (i > 0) const SizedBox(width: 9),
                Expanded(
                  child: _CountButton(
                    count: counts[i],
                    active: state.count == counts[i],
                    onTap: () => cubit.setCount(counts[i]),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pool.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1 / 0.85,
            ),
            itemBuilder: (context, i) => _SampleTile(id: pool[i]),
          ),
          const SizedBox(height: 4),
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: WardrobeTokens.infoLineBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'You can review each item separately before saving the batch.',
              style: AppTextStyles.dmSans(
                size: 10,
                color: WardrobeTokens.infoLineInk,
                height: 1.6,
              ),
            ),
          ),
          PrimaryButton(
            label:
                'Review ${state.count} ${state.count == 1 ? 'photo' : 'photos'} →',
            onPressed: () {
              cubit.makeDrafts();
              context.push(AppRoutes.batch);
            },
          ),
        ],
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.count,
    required this.active,
    required this.onTap,
  });

  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: active ? WardrobeTokens.countRowActiveBg : AppColors.white,
          border: Border.all(
            color: active
                ? WardrobeTokens.countRowActiveBorder
                : WardrobeTokens.countRowBorder,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count ${count == 1 ? 'item' : 'items'}',
          textAlign: TextAlign.center,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: active ? FontWeight.w800 : FontWeight.w400,
            color: active
                ? WardrobeTokens.countRowActiveInk
                : WardrobeTokens.countRowInk,
          ),
        ),
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
