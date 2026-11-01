import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'view/calendar_choose_view.dart';
import 'view/calendar_date_view.dart';
import 'view/calendar_view.dart';

/// Calendar planner (F09): month calendar, outfit chooser, and the
/// date/occasion confirmation screen.
final List<RouteBase> calendarRoutes = [
  GoRoute(
    path: AppRoutes.calendar,
    builder: (context, state) => const CalendarView(),
  ),
  GoRoute(
    path: AppRoutes.calendarChoose,
    builder: (context, state) => const CalendarChooseView(),
  ),
  GoRoute(
    path: AppRoutes.calendarDate,
    builder: (context, state) => const CalendarDateView(),
  ),
];
