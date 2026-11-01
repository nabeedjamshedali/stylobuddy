import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/data/seed_data.dart';
import '../../../shared/widgets/option_tile.dart';
import '../../../shared/widgets/screen_head.dart';
import '../cubit/wardrobe_browse_cubit.dart';

/// Prototype `pages.filter`.
class FilterView extends StatelessWidget {
  const FilterView({super.key});

  static const options = ['All', ...SeedData.categories];

  @override
  Widget build(BuildContext context) {
    final browse = context.read<WardrobeBrowseCubit>();
    final state = context.watch<WardrobeBrowseCubit>().state;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Wardrobe Filters',
            fallbackRoute: AppRoutes.wardrobe,
          ),
          Text(
            'Choose a category to narrow down the wardrobe.',
            style: AppTextStyles.dmSans(size: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 15),
          for (final option in options) ...[
            OptionTile(
              label: option,
              selected: state.filter == option,
              onTap: () {
                browse.setFilter(option);
                context.go(AppRoutes.wardrobe);
              },
            ),
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}
