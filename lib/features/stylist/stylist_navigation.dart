import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'cubit/stylist_cubit.dart';

/// Prototype `generate(mode)` routing: regenerate looks, then replace the
/// current route with the matching waiting screen. Shared by `/results` and
/// `/result-detail` (F03's "Refresh combinations" / "New suggestions"), and
/// reusable by F04/F05 for their own results and detail screens.
void refreshStylistResults(BuildContext context, {bool match = false}) {
  final cubit = context.read<StylistCubit>();
  if (match) {
    cubit.generateMatches();
    context.pushReplacement(AppRoutes.matchingProgress);
  } else {
    cubit.generateAutomatic();
    context.pushReplacement(AppRoutes.generating);
  }
}
