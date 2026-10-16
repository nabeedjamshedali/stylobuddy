import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../stylist/cubit/stylist_cubit.dart';
import '../../stylist/cubit/stylist_state.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../widgets/matching_page.dart';
import '../widgets/mm_chip.dart';
import '../widgets/mm_items_grid.dart';
import '../widgets/mm_selection.dart';
import '../widgets/mm_step_heading.dart';

/// Prototype `pages['match-select']`: pick candidate pieces (step 1 of 3).
class MatchSelectView extends StatelessWidget {
  const MatchSelectView({super.key});

  static const categories = [
    'All',
    'Shirts',
    'Pants',
    'Dresses',
    'Skirts',
    'Outerwear',
    'Shoes',
    'Accessories',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StylistCubit, StylistState>(
      builder: (context, state) {
        final cubit = context.read<StylistCubit>();
        final wardrobe = context.watch<WardrobeCubit>();
        final ids = [
          for (final item in wardrobe.state.items)
            if (state.category == 'All' || item.category == state.category)
              item.id,
        ];
        final count = state.selected.length;
        return MatchingPage(
          children: [
            const ScreenHead(
              title: 'Select Clothing',
              fallbackRoute: AppRoutes.matching,
            ),
            const MmStepHeading(
              step: 'STEP 1 OF 3',
              title: 'What should we match?',
              description:
                  'Select the pieces you want AI to compare. You can choose '
                  'multiple items in each category.',
            ),
            MmSelectionSummary(count: count),
            MmSelectionStrip(
              ids: state.selected,
              locked: state.locked.toSet(),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < categories.length; i++) ...[
                      if (i > 0) const SizedBox(width: 7),
                      MmChip(
                        label: categories[i],
                        selected: state.category == categories[i],
                        onTap: () => cubit.setCategory(categories[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            MmItemsGrid(
              mode: MmGridMode.select,
              ids: ids,
              marked: state.selected.toSet(),
              onTap: cubit.toggleSelect,
            ),
            PrimaryButton(
              label: 'Continue with $count item${count == 1 ? '' : 's'} →',
              onPressed: count == 0
                  ? null
                  : () => context.push(AppRoutes.matchReview),
            ),
          ],
        );
      },
    );
  }
}
