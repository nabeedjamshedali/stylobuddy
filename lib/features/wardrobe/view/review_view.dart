import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/data/seed_data.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/demo_note.dart';
import '../../../shared/widgets/garment_image.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../../shared/widgets/select_field.dart';
import '../cubit/import_cubit.dart';
import '../wardrobe_tokens.dart';

/// Prototype `pages.review` / `confirmBatchItem()`: review one AI suggestion
/// at a time. Missing drafts render a single line rather than crashing
/// (F06-A31).
class ReviewView extends StatefulWidget {
  const ReviewView({super.key});

  @override
  State<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<ReviewView> {
  TextEditingController? _nameController;
  String? _category;
  String? _color;
  String? _occasion;
  String? _season;
  int? _initializedForIndex;

  void _initFor(int index, String name, String category, String color,
      String occasion, String season) {
    if (_initializedForIndex == index) return;
    _nameController = TextEditingController(text: name);
    _category = category;
    _color = color;
    _occasion = occasion;
    _season = season;
    _initializedForIndex = index;
  }

  void _confirm(BuildContext context, ImportCubit cubit) {
    final error = cubit.confirmCurrent(
      name: _nameController!.text,
      category: _category!,
      color: _color!,
      occasion: _occasion!,
      season: _season!,
    );
    if (error != null) {
      AppToast.show(context, error);
      return;
    }
    if (cubit.state.drafts.isEmpty) {
      context.push(AppRoutes.addConfirm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ImportCubit>();
    final state = context.watch<ImportCubit>().state;
    final current = state.current;
    if (current == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenHead(
              title: 'Review Clothing',
              fallbackRoute: AppRoutes.batch,
            ),
            Text('No draft to review.', style: AppTextStyles.dmSans(size: 12)),
          ],
        ),
      );
    }
    _initFor(
      state.uploadIndex,
      current.name,
      current.category,
      current.color,
      current.occasion,
      current.season,
    );
    final total = state.drafts.length;
    final isLast = state.uploadIndex + 1 == total;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Review AI Suggestions',
            fallbackRoute: AppRoutes.batch,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ITEM ${state.uploadIndex + 1} OF $total',
                style: AppTextStyles.dmSans(
                  size: 9,
                  letterSpacing: 0.5,
                  color: WardrobeTokens.reviewProgress,
                ),
              ),
              Text(
                'AI suggestion · editable',
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w700,
                  color: WardrobeTokens.eyebrow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppProgressBar(value: (state.uploadIndex + 1) / total),
          const SizedBox(height: 17),
          Stack(
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: WardrobeTokens.reviewPhotoBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(child: GarmentImage(id: current.imageId)),
              ),
              Positioned(
                left: 12,
                bottom: 11,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    state.showOriginal
                        ? 'ORIGINAL PHOTO'
                        : 'CLEAN BACKGROUND · PREVIEW',
                    style: AppTextStyles.dmSans(
                      size: 8,
                      letterSpacing: 0.8,
                      color: WardrobeTokens.reviewPhotoLabel,
                    ),
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => cubit.toggleShowOriginal(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Text(
                state.showOriginal
                    ? 'Show cleaned preview ↗'
                    : 'Compare original image ↗',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w700,
                  color: WardrobeTokens.reviewToggle,
                ),
              ),
            ),
          ),
          Text(
            'Clothing name',
            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            style: AppTextStyles.dmSans(size: 12),
            decoration: const InputDecoration(isDense: true),
          ),
          SelectField(
            label: 'Category',
            options: SeedData.categories,
            value: _category!,
            onChanged: (v) => setState(() => _category = v),
          ),
          SelectField(
            label: 'Color',
            options: SeedData.colors,
            value: _color!,
            onChanged: (v) => setState(() => _color = v),
          ),
          SelectField(
            label: 'Best for',
            options: SeedData.occasions,
            value: _occasion!,
            onChanged: (v) => setState(() => _occasion = v),
          ),
          SelectField(
            label: 'Season',
            options: SeedData.seasons,
            value: _season!,
            onChanged: (v) => setState(() => _season = v),
          ),
          const SizedBox(height: 7),
          PrimaryButton(
            label: isLast ? 'Save to my wardrobe →' : 'Confirm & next item →',
            onPressed: () => _confirm(context, cubit),
          ),
          const DemoNote(
            'Metadata and background processing are illustrative, not '
            'actual AI output.',
          ),
        ],
      ),
    );
  }
}
