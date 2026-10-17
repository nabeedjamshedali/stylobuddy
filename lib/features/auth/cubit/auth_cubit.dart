import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/auth_repository.dart';
import 'auth_state.dart';

/// Email/password/forgot forms are demo-only (validate like the prototype's
/// `authSubmit`, no backend, no email sent) to keep the cloned prototype UI
/// intact. Google sign-in is wired to real Firebase Auth.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({AuthRepository? repository})
    : _repository = repository ?? AuthRepository(),
      super(const AuthState());

  final AuthRepository _repository;

  static const shortPasswordError =
      'Use at least 8 characters for your password.';
  static const mismatchError = 'Passwords do not match. Please try again.';

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isValidEmail(String value) =>
      _emailPattern.hasMatch(value.trim());

  /// No length rule on login; email and password are only required.
  AuthResult submitLogin({required String email, required String password}) {
    final invalid = <AuthFieldName>{
      if (!isValidEmail(email)) AuthFieldName.email,
      if (password.isEmpty) AuthFieldName.password,
    };
    if (invalid.isNotEmpty) return _block(AuthForm.login, invalid);
    return _accept(email);
  }

  AuthResult submitSignup({
    required String name,
    required String email,
    required String password,
    required String confirm,
  }) {
    final invalid = <AuthFieldName>{
      if (name.trim().length < 2) AuthFieldName.name,
      if (!isValidEmail(email)) AuthFieldName.email,
      if (password.isEmpty) AuthFieldName.password,
      if (confirm.isEmpty) AuthFieldName.confirm,
    };
    if (invalid.isNotEmpty) return _block(AuthForm.signup, invalid);
    if (password.length < 8) {
      return _reject(AuthForm.signup, shortPasswordError);
    }
    if (password != confirm) return _reject(AuthForm.signup, mismatchError);
    return _accept(email);
  }

  AuthResult submitForgot({required String email}) {
    if (!isValidEmail(email)) {
      return _block(AuthForm.forgot, {AuthFieldName.email});
    }
    return _accept(email);
  }

  /// Drops transient form state; called when a form screen is entered.
  void resetForm() =>
      emit(state.copyWith(clearError: true, invalidFields: const {}));

  /// The user edited [field]: its red state goes away.
  void clearInvalid(AuthFieldName field) {
    if (!state.invalidFields.contains(field)) return;
    emit(
      state.copyWith(invalidFields: {...state.invalidFields}..remove(field)),
    );
  }

  /// Required-field failure: nothing shown inline except the red border.
  AuthResult _block(AuthForm form, Set<AuthFieldName> invalid) {
    emit(state.copyWith(form: form, clearError: true, invalidFields: invalid));
    return AuthResult.failure;
  }

  AuthResult _reject(AuthForm form, String message) {
    emit(state.copyWith(form: form, error: message, invalidFields: const {}));
    return AuthResult.failure;
  }

  AuthResult _accept(String email) {
    emit(
      state.copyWith(
        email: email.trim(),
        clearError: true,
        invalidFields: const {},
      ),
    );
    return AuthResult.success;
  }

  /// Real Firebase Auth Google sign-in (the project's only wired provider).
  Future<AuthResult> signInWithGoogle() async {
    emit(
      state.copyWith(isGoogleSigningIn: true, clearGoogleError: true),
    );
    try {
      final user = await _repository.signInWithGoogle();
      emit(
        state.copyWith(
          email: user.email ?? '',
          isGoogleSigningIn: false,
          clearGoogleError: true,
        ),
      );
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      emit(
        state.copyWith(
          isGoogleSigningIn: false,
          googleError: e.message ?? 'Google sign-in failed.',
        ),
      );
      return AuthResult.failure;
    } on StateError {
      // User cancelled the Google account picker: not an error to surface.
      emit(state.copyWith(isGoogleSigningIn: false, clearGoogleError: true));
      return AuthResult.failure;
    } catch (_) {
      // Plugin/platform failure (no network, Play Services unavailable,
      // etc.) — show a generic message rather than crash the screen.
      emit(
        state.copyWith(
          isGoogleSigningIn: false,
          googleError: 'Google sign-in failed. Please try again.',
        ),
      );
      return AuthResult.failure;
    }
  }
}
