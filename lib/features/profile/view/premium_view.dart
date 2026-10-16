import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/screen_head.dart';
import '../widgets/pf_benefits_card.dart';
import '../widgets/pf_helper_text.dart';
import '../widgets/pf_paywall_card.dart';
import '../widgets/pf_section_title.dart';

/// Prototype `pages.premium`, `P/app.js:284`.
class PremiumView extends StatelessWidget {
  const PremiumView({super.key});

  static const benefits = [
    'Additional AI outfit recommendations',
    'Advanced garment matching',
    'Expanded style insights',
    'Smarter trip and calendar planning',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'StyloBuddy Plus',
            fallbackRoute: AppRoutes.profile,
          ),
          const PfPaywallCard(),
          const PfSectionTitle('PLANNED PREMIUM VALUE'),
          const PfBenefitsCard(benefits: benefits),
          const PfHelperText(
            'These are proposed benefits. Entitlements and pricing require '
            'cost review.',
          ),
          PrimaryButton(
            label: 'Preview plan options →',
            onPressed: () => context.push(AppRoutes.plan),
          ),
        ],
      ),
    );
  }
}
