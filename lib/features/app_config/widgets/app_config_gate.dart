import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/app_config_cubit.dart';
import '../cubit/app_config_state.dart';
import '../view/update_required_view.dart';
import 'app_notice_banner.dart';

/// Wraps the router's Navigator (`MaterialApp.router(builder:)`, F25 §2.3).
///
/// - Forced update: the app is kept alive but [Offstage] (not painted, not
///   hit-tested, no semantics) under [UpdateRequiredView].
/// - Maintenance notice / update nudge: banners above the app, which loses
///   its top inset to them.
/// - Otherwise: [child] is returned as-is, so the default tree is unchanged.
class AppConfigGate extends StatelessWidget {
  const AppConfigGate({super.key, required this.child});

  final Widget child;

  static const nudgeMessage = 'A new version of StyloBuddy is available.';
  static const nudgeAction = 'Update';
  static const nudgeDismissLabel = 'Dismiss update notice';
  static const maintenanceDismissLabel = 'Dismiss notice';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppConfigCubit, AppConfigState>(
      buildWhen: (previous, current) =>
          previous.updateRequired != current.updateRequired ||
          previous.showMaintenance != current.showMaintenance ||
          previous.maintenanceMessage != current.maintenanceMessage ||
          previous.showUpdateNudge != current.showUpdateNudge,
      builder: (context, state) {
        if (state.updateRequired) {
          return Stack(
            children: [
              Offstage(child: child),
              const UpdateRequiredView(),
            ],
          );
        }
        final banners = _banners(context, state);
        if (banners.isEmpty) return child;
        return Column(
          children: [
            ...banners,
            Expanded(
              // Own semantics container: the routes' modal barriers use
              // BlockSemantics, which would otherwise drop the banners
              // (painted earlier in the same container) from accessibility.
              child: Semantics(
                container: true,
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _banners(BuildContext context, AppConfigState state) {
    final cubit = context.read<AppConfigCubit>();
    final message = state.maintenanceMessage;
    return [
      if (state.showMaintenance && message != null)
        AppNoticeBanner(
          key: const Key('maintenance-banner'),
          message: message,
          dismissLabel: maintenanceDismissLabel,
          onDismiss: cubit.dismissMaintenance,
        ),
      if (state.showUpdateNudge)
        AppNoticeBanner(
          key: const Key('update-nudge-banner'),
          message: nudgeMessage,
          actionLabel: nudgeAction,
          onAction: cubit.openStore,
          dismissLabel: nudgeDismissLabel,
          onDismiss: cubit.dismissUpdateNudge,
          consumeTopInset: !state.showMaintenance,
        ),
    ];
  }
}
