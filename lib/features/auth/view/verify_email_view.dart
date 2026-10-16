import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_toast.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_notice.dart';
import '../widgets/auth_page.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_link.dart';

/// Prototype `pages['verify-email']`.
class VerifyEmailView extends StatelessWidget {
  const VerifyEmailView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      backRoute: AppRoutes.signup,
      title: 'One more step.',
      subtitle: 'Verify your email before saving your digital wardrobe.',
      children: [
        const AuthSuccessMark(mark: AuthMark.shield),
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) => AuthNotice(
            title: 'Verification preview',
            before: 'In production, we’ll send a verification email to ',
            email: state.email,
            after: '. This is an interactive design preview only.',
          ),
        ),
        AuthSubmitButton(
          label: 'Continue to demo',
          topMargin: 6,
          onPressed: () {
            AppToast.show(context, 'Verification simulated');
            context.go(AppRoutes.home);
          },
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AuthTextLink(
              label: 'Resend verification email',
              onTap: () => AppToast.show(
                context,
                'No real email is sent in this prototype',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
