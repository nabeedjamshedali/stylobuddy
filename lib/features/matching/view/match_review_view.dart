import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../stylist/cubit/stylist_cubit.dart';
import '../../stylist/cubit/stylist_state.dart';
import '../widgets/matching_page.dart';
import '../widgets/mm_lock_grid.dart';
import '../widgets/mm_notes.dart';
import '../widgets/mm_step_heading.dart';

/// Prototype `pages['match-review']`: lock must-wear pieces (step 2 of 3).
class MatchReviewView extends StatelessWidget {
  const MatchReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StylistCubit, StylistState>(
      builder: (context, state) {
        final cubit = context.read<StylistCubit>();
        final selected = state.selected;
        final locked = state.locked.toSet();
        final hasSelection = selected.isNotEmpty;
        return MatchingPage(
          children: [
            const ScreenHead(
              title: 'Review Your Selection',
              fallbackRoute: AppRoutes.matchSelect,
            ),
            MmStepHeading(
              step: 'STEP 2 OF 3',
              title: 'Anything you must wear?',
              description: '',
              descriptionSpans: [
                const TextSpan(text: 'Lock an item to include it in '),
                TextSpan(
                  text: 'every',
                  style: AppTextStyles.dmSans(
                    size: 12,
                    height: 1.6,
                    weight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text:
                      ' outfit. Leave other items as flexible candidates.',
                ),
              ],
            ),
            const MmLockLegend(),
            MmLockGrid(ids: selected, locked: locked, onTap: cubit.toggleLock),
            if (!hasSelection)
              const MmWarningNotice(
                'Choose at least one item before continuing.',
              )
            else
              MmNote(
                headline:
                    '${locked.length} required · ${selected.length - locked.length} flexible',
                body:
                    'Locked pieces cannot be removed by styling suggestions. '
                    'The preview will only show combinations compatible with '
                    'your selection.',
              ),
            SecondaryButton(
              label: 'Edit selected items',
              onPressed: () => context.push(AppRoutes.matchSelect),
            ),
            const SizedBox(height: 9),
            PrimaryButton(
              label: 'Continue to preferences →',
              onPressed: hasSelection
                  ? () => context.push(AppRoutes.matchOptions)
                  : null,
            ),
          ],
        );
      },
    );
  }
}
