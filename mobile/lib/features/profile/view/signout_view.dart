import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/demo_copy.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/screen_head.dart';
import '../widgets/pf_empty_state.dart';

/// Prototype `pages.signout`, `P/app.js:283`.
class SignoutView extends StatelessWidget {
  const SignoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Sign Out',
            fallbackRoute: AppRoutes.settings,
          ),
          const PfEmptyState(
            icon: '↪',
            title: 'Sign out of StyloBuddy?',
            body:
                'Sign in again to access your synced wardrobe in the '
                'future app.',
          ),
          PrimaryButton(
            label: 'Stay signed in',
            onPressed: () => context.go(AppRoutes.settings),
          ),
          const SizedBox(height: 20),
          SecondaryButton(
            label: DemoCopy.signoutButtonLabel,
            onPressed: () {
              context.go(AppRoutes.auth);
              AppToast.show(context, DemoCopy.signoutToast);
            },
          ),
        ],
      ),
    );
  }
}
