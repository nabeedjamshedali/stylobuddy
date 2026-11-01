import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/screen_head.dart';
import '../widgets/pf_empty_state.dart';

/// Prototype `pages.purchase`, `P/app.js:286`.
class PurchaseView extends StatelessWidget {
  const PurchaseView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(title: 'Checkout Preview', fallbackRoute: AppRoutes.plan),
          const PfEmptyState(
            icon: '✦',
            title: 'Checkout integration pending',
            body: 'StoreKit, Google Play Billing, purchase verification and '
                'entitlement syncing will be implemented later. No payment '
                'will be initiated.',
          ),
          PrimaryButton(
            label: 'View subscription settings',
            onPressed: () => context.push(AppRoutes.subscription),
          ),
        ],
      ),
    );
  }
}
