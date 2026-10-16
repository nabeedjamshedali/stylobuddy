/// Outcome of a demo submit. [failure] means "stay on the screen".
enum AuthResult { success, failure }

/// Names of the form fields, used to flag invalid inputs.
abstract final class AuthFieldName {
  static const name = 'name';
  static const email = 'email';
  static const password = 'password';
  static const confirm = 'confirm';
}

class AuthState {
  const AuthState({this.email = '', this.error, this.invalidFields = const {}});

  /// Email entered on the last successful submit; empty when none yet.
  final String email;

  /// Inline form error, null when hidden.
  final String? error;

  /// Fields that blocked the last submit (red border, no message).
  final Set<String> invalidFields;

  AuthState copyWith({
    String? email,
    String? error,
    bool clearError = false,
    Set<String>? invalidFields,
  }) => AuthState(
    email: email ?? this.email,
    error: clearError ? null : (error ?? this.error),
    invalidFields: invalidFields ?? this.invalidFields,
  );
}
