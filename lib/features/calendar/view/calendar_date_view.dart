import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/planned_entry.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../saved/cubit/outfits_cubit.dart';
import '../cubit/planner_cubit.dart';
import '../widgets/calendar_date_form.dart';
import '../widgets/calendar_heading.dart';
import '../widgets/calendar_plan_card.dart';
import '../widgets/calendar_primary_button.dart';

const _occasionOptions = [
  'Everyday',
  'Office',
  'Casual',
  'Date Night',
  'Wedding',
  'Party',
  'Travel',
  'Other',
];

/// Prototype `pages['calendar-date']`.
class CalendarDateView extends StatelessWidget {
  const CalendarDateView({super.key});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerCubit>();
    final state = planner.state;
    final outfitId = state.editingOutfitId;
    final outfit = outfitId != null
        ? context.watch<OutfitsCubit>().byId(outfitId)
        : null;

    if (outfit == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenHead(
              title: 'Plan an Outfit',
              fallbackRoute: AppRoutes.calendarChoose,
            ),
            Text(
              'Choose a saved outfit first.',
              style: AppTextStyles.dmSans(size: 12, color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    final occasion = state.editingOccasion ?? outfit.occasion;
    final selectedDate = DateTime(state.year, state.month, state.day);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Plan an Outfit',
            fallbackRoute: AppRoutes.calendarChoose,
          ),
          const CalendarHeading(
            eyebrow: 'ALMOST THERE',
            title: 'Schedule your outfit.',
            subtitle: 'A little planning goes a long way.',
          ),
          const SizedBox(height: 15),
          CalendarPlanCard(
            items: outfit.items,
            name: outfit.name,
            subtitle: '${outfit.items.length} items in your wardrobe',
            eyebrow: 'SELECTED LOOK',
          ),
          CalendarDateForm(
            dateValue: planner.selectedKey,
            initialDate: selectedDate,
            onDateChanged: (date) =>
                context.read<PlannerCubit>().selectDate(date),
            occasion: occasion,
            occasionOptions: _occasionOptions,
            onOccasionChanged: (value) => context
                .read<PlannerCubit>()
                .startScheduling(outfit.id, value),
          ),
          CalendarPrimaryButton(
            label: 'Confirm outfit plan',
            onPressed: () => _confirm(context, outfit.id, occasion),
          ),
        ],
      ),
    );
  }

  void _confirm(BuildContext context, int outfitId, String occasion) {
    final plannerCubit = context.read<PlannerCubit>();
    final key = plannerCubit.selectedKey;
    plannerCubit.plan(key, PlannedEntry(outfitId: outfitId, occasion: occasion));
    final label = plannerCubit.label(key);
    plannerCubit.clearEditing();
    context.go(AppRoutes.calendar);
    AppToast.show(context, 'Outfit planned for $label');
  }
}
