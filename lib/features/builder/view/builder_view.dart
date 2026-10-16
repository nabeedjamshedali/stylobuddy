import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../builder_tokens.dart';
import '../cubit/builder_cubit.dart';
import '../cubit/builder_state.dart';
import '../widgets/mb_categories.dart';
import '../widgets/mb_intro.dart';
import '../widgets/mb_live_preview.dart';
import '../widgets/mb_wardrobe_grid.dart';

/// Prototype `pages.builder`.
class BuilderView extends StatelessWidget {
  const BuilderView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BuilderCubit, BuilderState>(
      builder: (context, state) {
        final cubit = context.read<BuilderCubit>();
        final wardrobe = context.watch<WardrobeCubit>();
        final items = wardrobe.state.items;
        final filtered = [
          for (final item in items)
            if (state.category == 'All' || item.category == state.category)
              item.id,
        ];
        final count = state.picked.length;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHead(
                title: state.isEditing ? 'Edit Your Outfit' : 'Build Your Outfit',
                fallbackRoute: AppRoutes.wardrobe,
              ),
              const MbIntro(
                kicker: 'YOUR PERSONAL LOOK',
                title: 'Put your pieces together.',
                body:
                    'Choose items from your wardrobe. Watch your look come '
                    'together as you select.',
              ),
              MbLivePreview(picked: state.picked, onRemove: cubit.remove),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 21, 0, 11),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Choose from your wardrobe',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${items.length} pieces',
                      style: AppTextStyles.dmSans(
                        size: 10,
                        color: BuilderTokens.collectionCount,
                      ),
                    ),
                  ],
                ),
              ),
              MbCategories(
                categories: MbCategories.all,
                selected: state.category,
                onSelect: cubit.setCategory,
              ),
              MbWardrobeGrid(
                ids: filtered,
                picked: state.picked.toSet(),
                onTap: cubit.toggle,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: PrimaryButton(
                  label: 'Preview $count ${count == 1 ? 'item' : 'items'} →',
                  onPressed: count == 0
                      ? null
                      : () => context.push(AppRoutes.manualPreview),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
