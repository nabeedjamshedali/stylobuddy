import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/models/outfit.dart';
import '../../../shared/models/planned_entry.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../calendar/cubit/planner_cubit.dart';
import '../../calendar/cubit/planner_state.dart';
import '../../saved/cubit/outfits_cubit.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../cubit/stylist_cubit.dart';
import '../models/look_piece.dart';
import '../models/style_result.dart';
import '../stylist_navigation.dart';
import '../widgets/detail_board.dart';
import '../widgets/detail_heading.dart';
import '../widgets/detail_modals.dart';
import '../widgets/detail_panels.dart';
import '../widgets/stylist_page.dart';
import 'stylist_view.dart';

/// Prototype `resultDetails(match)`. Shared by `/result-detail` and (via F04)
/// `/matching-detail`.
class ResultDetailView extends StatelessWidget {
  const ResultDetailView({super.key, this.match = false});

  final bool match;

  Outfit _ensureSaved(BuildContext context, StyleResult r) =>
      context.read<OutfitsCubit>().saveOrFind(
        Outfit(
          id: 0,
          name: r.name,
          occasion: r.occasion,
          items: r.items,
          why: r.why,
        ),
      );

  void _save(BuildContext context, StyleResult r) {
    final outfit = _ensureSaved(context, r);
    AppToast.show(context, 'Saved to your outfits');
    context.push(AppRoutes.savedDetail(outfit.id));
  }

  void _plan(BuildContext context, StyleResult r) {
    final outfit = _ensureSaved(context, r);
    final planner = context.read<PlannerCubit>();
    final router = GoRouter.of(context);
    AppModal.show(
      context,
      title: 'Plan this outfit',
      body: Builder(
        builder: (dialogContext) =>
            BlocBuilder<PlannerCubit, PlannerState>(
              bloc: planner,
              builder: (_, planState) => PlanModalBody(
                outfitName: outfit.name,
                chosenDay: planState.day,
                onPick: (day) {
                  planner.startScheduling(outfit.id, outfit.occasion);
                  planner.plan(
                    PlannerCubit.keyFor(2026, 10, day),
                    PlannedEntry(outfitId: outfit.id, occasion: outfit.occasion),
                  );
                  planner.select(day);
                  planner.clearEditing();
                  AppModal.close(dialogContext);
                  router.push(AppRoutes.calendar);
                  AppToast.show(context, 'Outfit scheduled for October $day');
                },
              ),
            ),
      ),
    );
  }

  void _swap(BuildContext context, StyleResult r, LookPiece piece) {
    final wardrobe = context.read<WardrobeCubit>();
    final alternatives = [
      for (final it in wardrobe.state.items)
        if (it.category == piece.item.category &&
            it.id != piece.id &&
            !r.items.contains(it.id))
          it,
    ];
    if (alternatives.isEmpty) {
      AppToast.show(
        context,
        'No alternative in your wardrobe for this category',
      );
      return;
    }
    final stylist = context.read<StylistCubit>();
    AppModal.show(
      context,
      title: 'Swap ${piece.name}',
      body: Builder(
        builder: (dialogContext) => SwapModalBody(
          category: piece.item.category,
          alternatives: alternatives,
          onPick: (it) {
            final message = stylist.swapItem(piece.id, it.id);
            if (message == null) return;
            if (message == StylistCubit.swappedMessage) {
              AppModal.close(dialogContext);
            }
            AppToast.show(context, message);
          },
        ),
      ),
    );
  }

  void _share(BuildContext context) {
    final summary = context.read<StylistCubit>().shareSummary();
    AppModal.show(
      context,
      title: 'Share this look',
      body: Builder(
        builder: (dialogContext) => ShareModalBody(
          summary: summary,
          onCopy: () async {
            String message;
            try {
              await Clipboard.setData(ClipboardData(text: summary));
              message = 'Outfit details copied';
            } catch (_) {
              message = 'Select and copy the text above';
            }
            if (context.mounted) AppToast.show(context, message);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StylistCubit>().state;
    final wardrobe = context.watch<WardrobeCubit>();
    final r = state.activeResult;
    // Missing (not empty): no results at all falls back to the stylist hub.
    if (r == null) return const StylistView();
    final index = state.results.indexOf(r);
    final pieces = [
      for (final id in r.items)
        LookPiece(
          item: wardrobe.itemOrFallback(id),
          locked: match && state.locked.contains(id),
        ),
    ];
    return StylistPage(
      children: [
        ScreenHead(
          title: 'Outfit Details',
          fallbackRoute: match ? AppRoutes.matchingResults : AppRoutes.results,
        ),
        DetailHeading(
          index: index,
          total: state.results.length,
          name: r.name,
          onSave: () => _save(context, r),
        ),
        DetailBoard(
          pieces: pieces,
          onOpen: (p) => context.push(AppRoutes.clothing(p.id)),
        ),
        const DetailWardrobeNote(),
        DetailWhyPanel(why: r.why, occasion: state.occasion),
        DetailItemsPanel(
          pieces: pieces,
          onSwap: (p) => _swap(context, r, p),
        ),
        DetailActions(
          onSave: () => _save(context, r),
          onPlan: () => _plan(context, r),
          onShare: () => _share(context),
          onRefresh: () => refreshStylistResults(context, match: match),
        ),
        const DetailFootnote(),
      ],
    );
  }
}
