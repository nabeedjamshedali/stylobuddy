import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/demo_copy.dart';
import '../../../shared/widgets/app_toast.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_error_text.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_page.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_link.dart';

/// Prototype `pages.login`.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AuthCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) => cubit.resetForm());
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final result = context.read<AuthCubit>().submitLogin(
      email: _email.text,
      password: _password.text,
    );
    if (result == AuthResult.success) {
      AppToast.show(context, DemoCopy.loginSuccessToast);
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      backRoute: AppRoutes.auth,
      title: 'Welcome back.',
      subtitle: 'Sign in to continue building your personal wardrobe.',
      foot: AuthFoot(
        text: 'New to StyloBuddy?',
        linkLabel: 'Create an account',
        onLink: () => context.push(AppRoutes.signup),
      ),
      children: [
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                label: 'Email address',
                controller: _email,
                placeholder: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                invalid: state.isInvalid(AuthForm.login, AuthFieldName.email),
                onChanged: () =>
                    context.read<AuthCubit>().clearInvalid(AuthFieldName.email),
              ),
              const SizedBox(height: 15),
              AuthField(
                label: 'Password',
                controller: _password,
                placeholder: 'Enter your password',
                isPassword: true,
                invalid: state.isInvalid(
                  AuthForm.login,
                  AuthFieldName.password,
                ),
                onChanged: () => context.read<AuthCubit>().clearInvalid(
                  AuthFieldName.password,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: AuthTextLink(
                  label: 'Forgot password?',
                  onTap: () => context.push(AppRoutes.forgot),
                ),
              ),
              if (state.errorFor(AuthForm.login) != null) ...[
                const SizedBox(height: 15),
                AuthErrorText(state.errorFor(AuthForm.login)),
              ],
              AuthSubmitButton(
                label: 'Sign in',
                topMargin: 21,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
