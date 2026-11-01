import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../saved/cubit/outfits_cubit.dart';
import '../cubit/planner_cubit.dart';
import '../widgets/calendar_alt_button.dart';
import '../widgets/calendar_empty_card.dart';
import '../widgets/calendar_heading.dart';
import '../widgets/calendar_outfit_tile.dart';

/// Prototype `pages['calendar-choose']`.
class CalendarChooseView extends StatelessWidget {
  const CalendarChooseView({super.key});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerCubit>();
    final outfits = context.watch<OutfitsCubit>().state.outfits;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Choose an Outfit',
            fallbackRoute: AppRoutes.calendar,
          ),
          CalendarHeading(
            eyebrow:
                'PLANNING FOR ${planner.label(planner.selectedKey).toUpperCase()}',
            title: 'Pick your look.',
            subtitle: 'Select any saved outfit to add it to your calendar.',
          ),
          const SizedBox(height: 20),
          if (outfits.isEmpty)
            const CalendarEmptyCard(
              title: 'No saved outfits yet',
              body: 'Build or generate an outfit first.',
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final outfit in outfits)
                  CalendarOutfitTile(
                    items: outfit.items,
                    name: outfit.name,
                    occasion: outfit.occasion,
                    pieceCount: outfit.items.length,
                    onTap: () {
                      context.read<PlannerCubit>().startScheduling(
                        outfit.id,
                        outfit.occasion,
                      );
                      context.push(AppRoutes.calendarDate);
                    },
                  ),
              ],
            ),
          const SizedBox(height: 11),
          CalendarAltButton(
            label: '+ Build a new outfit',
            onPressed: () => context.push(AppRoutes.builder),
          ),
          CalendarAltButton(
            label: '✧ Generate an AI outfit',
            onPressed: () => context.push(AppRoutes.occasion),
          ),
        ],
      ),
    );
  }
}
