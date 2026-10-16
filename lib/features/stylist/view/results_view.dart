import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/demo_note.dart';
import '../../../shared/widgets/screen_head.dart';
import '../cubit/stylist_cubit.dart';
import '../cubit/stylist_state.dart';
import '../widgets/link_action.dart';
import '../widgets/look_card.dart';
import '../widgets/no_matches.dart';
import '../stylist_navigation.dart';
import '../widgets/results_header.dart';
import '../widgets/stylist_page.dart';

/// Prototype `showResults(match)`. Shared by `/results` and (via F04)
/// `/matching-results`.
class ResultsView extends StatelessWidget {
  const ResultsView({super.key, this.match = false});

  final bool match;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StylistCubit, StylistState>(
      buildWhen: (a, b) =>
          a.results != b.results ||
          a.occasion != b.occasion ||
          a.locked != b.locked ||
          a.selected != b.selected,
      builder: (context, state) {
        final cubit = context.read<StylistCubit>();
        final results = state.results;
        final locked = state.locked.length;
        return StylistPage(
          children: [
            ScreenHead(
              title: match ? 'Your Best Matches' : 'Outfit Recommendations',
              fallbackRoute: match ? AppRoutes.matchReview : AppRoutes.stylist,
            ),
            ResultsHeader(
              count: results.length,
              occasion: state.occasion,
              contextLine: match
                  ? '$locked locked must-wear item${locked == 1 ? '' : 's'} · ${state.selected.length} selected candidates'
                  : null,
            ),
            if (results.isEmpty)
              const NoMatches()
            else
              for (var i = 0; i < results.length; i++)
                LookCard(
                  result: results[i],
                  index: i,
                  total: results.length,
                  onTap: () {
                    cubit.setActiveIndex(i);
                    context.push(
                      match ? AppRoutes.matchingDetail : AppRoutes.resultDetail,
                    );
                  },
                ),
            SecondaryButton(
              label: match ? 'Edit chosen clothing' : 'Change occasion',
              onPressed: () => context.push(
                match ? AppRoutes.matchSelect : AppRoutes.occasion,
              ),
            ),
            LinkAction(
              label: '↻ Refresh combinations',
              onTap: () => refreshStylistResults(context, match: match),
            ),
            const DemoNote(
              'Styling examples are simulated. No real AI evaluation or percentage scores are claimed.',
              style: DemoNoteStyle.ai,
            ),
          ],
        );
      },
    );
  }
}
