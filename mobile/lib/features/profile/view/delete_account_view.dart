import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/demo_copy.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/screen_head.dart';
import '../widgets/pf_form_intro.dart';
import '../widgets/pf_warning_box.dart';

/// Prototype `pages['delete-account']`, `P/app.js:282`.
class DeleteAccountView extends StatelessWidget {
  const DeleteAccountView({super.key});

  void _reviewDeletion(BuildContext context) {
    AppModal.show(
      context,
      title: 'Deletion preview',
      body: Builder(
        builder: (dialogContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(DemoCopy.deleteAccountModalBody),
            const SizedBox(height: 16),
            SecondaryButton(
              label: 'Close',
              onPressed: () => AppModal.close(dialogContext),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Delete Account',
            fallbackRoute: AppRoutes.support,
          ),
          const PfFormIntro(
            title: 'Your account, your choice.',
            body:
                'In production, deletion will include your account and '
                'stored wardrobe data, with clear information about active '
                'subscriptions.',
          ),
          const PfWarningBox(DemoCopy.deleteAccountWarning),
          DangerButton(
            label: 'Review deletion',
            onPressed: () => _reviewDeletion(context),
          ),
        ],
      ),
    );
  }
}
