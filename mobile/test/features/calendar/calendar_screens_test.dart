import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/core/router/app_routes.dart';
import 'package:stylobuddy/features/calendar/cubit/planner_cubit.dart';
import 'package:stylobuddy/features/calendar/widgets/calendar_days_grid.dart';
import 'package:stylobuddy/features/saved/cubit/outfits_cubit.dart';
import 'package:stylobuddy/shared/models/planned_entry.dart';

import '../support/f02_harness.dart';

T cubitOf<T extends StateStreamableSource<Object?>>(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first).read<T>();

/// Changes the open date picker's value by switching to text-entry mode and
/// typing a US-format (`MM/dd/yyyy`) date, then confirms with 'OK'.
Future<void> typeDatePickerDate(WidgetTester tester, String mmDdYyyy) async {
  await tester.tap(find.byType(IconButton).first);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, mmDdYyyy);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('F09_A01 calendar opens on October 2026 with full day grid', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.calendar);
    for (final t in [
      'Outfit Planner',
      'YOUR STYLE CALENDAR',
      'Plan your looks ahead.',
      'One less thing to decide every morning.',
      'YOUR MONTH',
      'October 2026',
      'Su',
      'Mo',
      'Tu',
      'We',
      'Th',
      'Fr',
      'Sa',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    expect(find.byType(CalendarDayButton), findsNWidgets(31));
    expect(find.byType(CalendarBlankCell), findsNWidgets(4));
  });

  testWidgets('F09_A02 day 15 active with planned marker and selected label', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.calendar);
    final day15 = tester.widget<CalendarDayButton>(
      find.byWidgetPredicate(
        (w) => w is CalendarDayButton && w.day == 15,
      ),
    );
    expect(day15.active, isTrue);
    expect(day15.planned, isTrue);
    expect(find.text('SELECTED DATE'), findsOneWidget);
    expect(find.text('October 15, 2026'), findsOneWidget);
  });

  testWidgets('F09_A03 seed plan renders the planned-look card', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.calendar);
    for (final t in [
      'YOUR PLANNED LOOK',
      'Everyday Essential',
      'Everyday · 4 pieces',
      'View outfit ↗',
      'Remove',
      'Change planned outfit →',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    await tester.tap(find.text('Everyday Essential'));
    await tester.pumpAndSettle();
    expect(pathOf(router), startsWith(AppRoutes.savedDetailPath));
  });

  testWidgets('F09_A04 summary reflects planned count for the month', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.calendar);
    expect(find.text('✧ 1 planned look this month'), findsOneWidget);
    expect(find.text('● Planned outfit'), findsOneWidget);

    final planner = cubitOf<PlannerCubit>(tester);
    planner.remove('2026-10-15');
    await tester.pumpAndSettle();
    expect(find.text('✧ 0 planned looks this month'), findsOneWidget);

    planner.plan(
      '2026-10-02',
      const PlannedEntry(outfitId: 1, occasion: 'Everyday'),
    );
    planner.plan(
      '2026-10-03',
      const PlannedEntry(outfitId: 2, occasion: 'Casual'),
    );
    await tester.pumpAndSettle();
    expect(find.text('✧ 2 planned looks this month'), findsOneWidget);
  });

  testWidgets('F09_A05 selecting an unplanned day shows the empty card', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.calendar);
    final planner = cubitOf<PlannerCubit>(tester);
    planner.select(20);
    await tester.pumpAndSettle();
    expect(find.text('No outfit planned yet'), findsOneWidget);
    expect(
      find.text('Choose one of your saved looks for this day.'),
      findsOneWidget,
    );
    expect(find.text('+ Plan an outfit →'), findsOneWidget);
    expect(find.text('Remove'), findsNothing);
  });

  testWidgets('F09_A06 next month clamps day 31 and drops October\'s plan '
      'from the summary', (tester) async {
    await pumpApp(tester, AppRoutes.calendar);
    final planner = cubitOf<PlannerCubit>(tester);
    planner.select(31);
    await tester.pumpAndSettle();
    await tester.tap(find.text('›'));
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsOneWidget);
    final day30 = tester.widget<CalendarDayButton>(
      find.byWidgetPredicate((w) => w is CalendarDayButton && w.day == 30),
    );
    expect(day30.active, isTrue);
    // October's seed plan is not counted in November.
    expect(find.text('✧ 0 planned looks this month'), findsOneWidget);
  });

  testWidgets('F09_A06 previous month from October shows September', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.calendar);
    await tester.tap(find.text('‹').last);
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);
  });

  testWidgets('F09_A07 secondary actions navigate', (tester) async {
    var router = await pumpApp(tester, AppRoutes.calendar);
    await tapText(tester, 'View saved looks ↗');
    expect(pathOf(router), AppRoutes.saved);

    router = await pumpApp(tester, AppRoutes.calendar);
    await tapText(tester, '✧ Ask AI for a look');
    expect(pathOf(router), AppRoutes.occasion);
  });

  testWidgets('F09_A08 calendar-choose lists the saved outfits', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.calendarChoose);
    for (final t in [
      'Choose an Outfit',
      'PLANNING FOR OCTOBER 15, 2026',
      'Pick your look.',
      'Select any saved outfit to add it to your calendar.',
      'Everyday Essential',
      'Everyday · 4 pieces',
      'Modern Weekend',
      'Casual · 4 pieces',
      '+ Build a new outfit',
      '✧ Generate an AI outfit',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
  });

  testWidgets('F09_A09 calendar-choose empty state differs from a list', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.calendarChoose);
    final outfits = cubitOf<OutfitsCubit>(tester);
    outfits.delete(1);
    outfits.delete(2);
    await tester.pumpAndSettle();
    expect(find.text('No saved outfits yet'), findsOneWidget);
    expect(find.text('Build or generate an outfit first.'), findsOneWidget);
  });

  testWidgets('F09_A10 choosing an outfit opens calendar-date pre-filled', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.calendarChoose);
    await tapText(tester, 'Everyday Essential');
    expect(pathOf(router), AppRoutes.calendarDate);
    for (final t in [
      'ALMOST THERE',
      'Schedule your outfit.',
      'A little planning goes a long way.',
      'SELECTED LOOK',
      'Everyday Essential',
      '4 items in your wardrobe',
      '2026-10-15',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    expect(find.text('Everyday'), findsWidgets); // occasion default
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    for (final o in [
      'Everyday',
      'Office',
      'Casual',
      'Date Night',
      'Wedding',
      'Party',
      'Travel',
      'Other',
    ]) {
      expect(find.text(o), findsWidgets, reason: o);
    }
  });

  testWidgets('F09_A11 calendar-date with no draft prompts to choose first', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.calendarDate);
    expect(find.text('Plan an Outfit'), findsOneWidget);
    expect(find.text('Choose a saved outfit first.'), findsOneWidget);
  });

  testWidgets('F09_A12 confirming on Oct 15 stores the plan and toasts', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.calendarChoose);
    await tapText(tester, 'Modern Weekend');
    expect(pathOf(router), AppRoutes.calendarDate);

    await tapText(tester, 'Confirm outfit plan →');
    expect(pathOf(router), AppRoutes.calendar);
    expect(find.text('Outfit planned for October 15, 2026'), findsOneWidget);

    final planner = cubitOf<PlannerCubit>(tester);
    expect(planner.state.planned['2026-10-15']!.outfitId, 2);
    await drainToast(tester);
  });

  testWidgets('F09_A13 changing the date field moves the plan and selection', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.calendarChoose);
    await tapText(tester, 'Everyday Essential');
    expect(pathOf(router), AppRoutes.calendarDate);

    await tester.tap(find.text('2026-10-15'));
    await tester.pumpAndSettle();
    await typeDatePickerDate(tester, '11/02/2026');
    expect(find.text('2026-11-02'), findsOneWidget);

    await tapText(tester, 'Confirm outfit plan →');
    expect(pathOf(router), AppRoutes.calendar);
    expect(find.text('Outfit planned for November 2, 2026'), findsOneWidget);

    final planner = cubitOf<PlannerCubit>(tester);
    expect(planner.state.planned['2026-11-02']!.outfitId, 1);
    expect((planner.state.year, planner.state.month, planner.state.day), (
      2026,
      11,
      2,
    ));
    await drainToast(tester);
  });

  testWidgets('F09_A14 planning a second outfit on the same day replaces it', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.calendar);
    final planner = cubitOf<PlannerCubit>(tester);
    planner.plan(
      '2026-10-15',
      const PlannedEntry(outfitId: 1, occasion: 'Everyday'),
    );
    planner.plan(
      '2026-10-15',
      const PlannedEntry(outfitId: 2, occasion: 'Casual'),
    );
    expect(planner.state.planned.length, 1);
    expect(planner.state.planned['2026-10-15']!.outfitId, 2);
  });

  testWidgets('F09_A15 remove modal: Keep plan closes and keeps the plan', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.calendar);
    await tapText(tester, 'Remove');
    for (final t in [
      'Remove this plan?',
      'This only removes the calendar plan. Your saved outfit stays in '
          'My Looks.',
      'Keep plan',
      'Remove plan',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    await tapText(tester, 'Keep plan');
    expect(find.text('Remove this plan?'), findsNothing);
    final planner = cubitOf<PlannerCubit>(tester);
    expect(planner.state.planned.containsKey('2026-10-15'), isTrue);
  });

  testWidgets('F09_A16 remove plan deletes the entry without removing the '
      'outfit', (tester) async {
    await pumpApp(tester, AppRoutes.calendar);
    await tapText(tester, 'Remove');
    await tapText(tester, 'Remove plan');
    expect(find.text('Plan removed'), findsOneWidget);
    expect(find.text('No outfit planned yet'), findsOneWidget);

    final planner = cubitOf<PlannerCubit>(tester);
    expect(planner.state.planned.containsKey('2026-10-15'), isFalse);
    final outfits = cubitOf<OutfitsCubit>(tester);
    expect(outfits.byId(1), isNotNull);
    await drainToast(tester);
  });

  testWidgets('F09_A17 a plan whose outfit was deleted shows the empty card '
      'without crashing, still counted in the summary', (tester) async {
    await pumpApp(tester, AppRoutes.calendar);
    final outfits = cubitOf<OutfitsCubit>(tester);
    outfits.delete(1);
    await tester.pumpAndSettle();
    expect(find.text('No outfit planned yet'), findsOneWidget);
    expect(find.text('✧ 1 planned look this month'), findsOneWidget);
  });

  testWidgets('F09_A18 header back targets', (tester) async {
    var router = await pumpApp(tester, AppRoutes.calendar);
    await tester.tap(find.text('‹').first);
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.home);

    router = await pumpApp(tester, AppRoutes.calendarChoose);
    await tester.tap(find.text('‹').first);
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.calendar);

    router = await pumpApp(tester, AppRoutes.calendarDate);
    await tester.tap(find.text('‹').first);
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.calendarChoose);
  });

  testWidgets('F09_A22 the draft holds the chosen outfit and clears on '
      'confirm', (tester) async {
    final router = await pumpApp(tester, AppRoutes.calendarChoose);
    await tapText(tester, 'Modern Weekend');
    final planner = cubitOf<PlannerCubit>(tester);
    expect(planner.state.editingOutfitId, 2);
    expect(planner.state.editingOccasion, 'Casual');

    await tapText(tester, 'Confirm outfit plan →');
    expect(pathOf(router), AppRoutes.calendar);
    expect(planner.state.editingOutfitId, isNull);
    expect(planner.state.editingOccasion, isNull);
    await drainToast(tester);
  });
}
