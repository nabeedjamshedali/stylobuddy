import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/demo_copy.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_notice.dart';
import '../widgets/auth_page.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_link.dart';

/// Prototype `pages['reset-sent']`.
class ResetSentView extends StatelessWidget {
  const ResetSentView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      backRoute: AppRoutes.forgot,
      title: 'Check your inbox.',
      subtitle: DemoCopy.resetSentSubtitle,
      children: [
        const AuthSuccessMark(mark: AuthMark.mail),
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) => AuthNotice(
            title: 'Reset link preview',
            before: 'In the real app, a secure link would be sent to ',
            email: state.email,
            after: DemoCopy.resetSentNoticeAfter,
          ),
        ),
        AuthSubmitButton(
          label: 'Back to sign in',
          topMargin: 6,
          onPressed: () => context.go(AppRoutes.login),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AuthTextLink(
              label: 'Try another email',
              onTap: () => context.go(AppRoutes.forgot),
            ),
          ),
        ),
      ],
    );
  }
}
