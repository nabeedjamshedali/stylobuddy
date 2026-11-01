import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/demo_copy.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/screen_head.dart';
import '../widgets/pf_empty_state.dart';

/// Prototype `pages['support-detail']`, `P/app.js:281`.
class SupportDetailView extends StatelessWidget {
  const SupportDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Help & Information',
            fallbackRoute: AppRoutes.support,
          ),
          const PfEmptyState(
            icon: 'ⓘ',
            title: 'Coming before launch',
            body: DemoCopy.supportDetailBody,
          ),
          SecondaryButton(
            label: 'Back to help',
            onPressed: () => context.go(AppRoutes.support),
          ),
        ],
      ),
    );
  }
}
