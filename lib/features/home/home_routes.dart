import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'view/home_view.dart';

final List<RouteBase> homeRoutes = [
  GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeView()),
];
