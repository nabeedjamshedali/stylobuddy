import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../saved/cubit/outfits_cubit.dart';
import '../cubit/planner_cubit.dart';
import '../widgets/calendar_days_grid.dart';
import '../widgets/calendar_empty_card.dart';
import '../widgets/calendar_heading.dart';
import '../widgets/calendar_month_bar.dart';
import '../widgets/calendar_plan_card.dart';
import '../widgets/calendar_primary_button.dart';
import '../widgets/calendar_secondary_actions.dart';
import '../widgets/calendar_selected_head.dart';
import '../widgets/calendar_summary_row.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Prototype `pages.calendar`.
class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  void _removePlan(BuildContext context) {
    AppModal.show(
      context,
      title: 'Remove this plan?',
      body: Builder(
        builder: (dialogContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This only removes the calendar plan. Your saved outfit '
              'stays in My Looks.',
            ),
            const SizedBox(height: 17),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Keep plan',
                    onPressed: () => AppModal.close(dialogContext),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Remove plan',
                    onPressed: () {
                      final key = context.read<PlannerCubit>().selectedKey;
                      context.read<PlannerCubit>().remove(key);
                      AppModal.close(dialogContext);
                      AppToast.show(context, 'Plan removed');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerCubit>();
    final plannerCubit = context.read<PlannerCubit>();
    final outfits = context.watch<OutfitsCubit>();
    final state = planner.state;

    final month = DateTime(state.year, state.month, 1);
    final monthLabel = '${_monthNames[state.month - 1]} ${state.year}';
    final daysInMonth = DateTime(state.year, state.month + 1, 0).day;
    final leadingBlanks = month.weekday % 7; // DateTime: Mon=1..Sun=7

    final selectedKey = planner.selectedKey;
    final entry = state.planned[selectedKey];
    final outfit = entry != null ? outfits.byId(entry.outfitId) : null;

    final monthPrefix =
        '${state.year.toString().padLeft(4, '0')}-${state.month.toString().padLeft(2, '0')}';
    final plannedCount = state.planned.keys
        .where((k) => k.startsWith(monthPrefix))
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(title: 'Outfit Planner', fallbackRoute: AppRoutes.home),
          const CalendarHeading(
            eyebrow: 'YOUR STYLE CALENDAR',
            title: 'Plan your looks ahead.',
            subtitle: 'One less thing to decide every morning.',
          ),
          const SizedBox(height: 6),
          CalendarMonthBar(
            monthLabel: monthLabel,
            onPrevious: () => plannerCubit.navigate(-1),
            onNext: () => plannerCubit.navigate(1),
          ),
          CalendarDaysGrid(
            daysInMonth: daysInMonth,
            leadingBlanks: leadingBlanks,
            activeDay: state.day,
            monthLabel: monthLabel,
            isPlanned: (day) => state.planned.containsKey(
              '$monthPrefix-${day.toString().padLeft(2, '0')}',
            ),
            onSelect: plannerCubit.select,
          ),
          CalendarSummaryRow(plannedCount: plannedCount),
          CalendarSelectedHead(
            label: planner.label(selectedKey),
            onRemove: outfit != null ? () => _removePlan(context) : null,
          ),
          if (outfit != null)
            CalendarPlanCard(
              items: outfit.items,
              name: outfit.name,
              subtitle:
                  '${entry?.occasion ?? outfit.occasion} · ${outfit.items.length} pieces',
              onTap: () => context.push(AppRoutes.savedDetail(outfit.id)),
            )
          else
            const CalendarEmptyCard(
              title: 'No outfit planned yet',
              body: 'Choose one of your saved looks for this day.',
            ),
          const SizedBox(height: 12),
          CalendarPrimaryButton(
            label: outfit != null ? 'Change planned outfit' : '+ Plan an outfit',
            onPressed: () => context.push(AppRoutes.calendarChoose),
          ),
          CalendarSecondaryActions(
            onViewSaved: () => context.push(AppRoutes.saved),
            onAskAi: () => context.push(AppRoutes.occasion),
          ),
        ],
      ),
    );
  }
}
