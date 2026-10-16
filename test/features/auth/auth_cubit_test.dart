import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/auth/cubit/auth_cubit.dart';
import 'package:stylobuddy/features/auth/cubit/auth_state.dart';

AuthResult _signup(
  AuthCubit c, {
  String name = 'Jo',
  String email = 'you@example.com',
  String password = 'longenough',
  String confirm = 'longenough',
}) => c.submitSignup(
  name: name,
  email: email,
  password: password,
  confirm: confirm,
);

void main() {
  group('AuthCubit', () {
    test('F02_A03 signup with short password sets the length error', () {
      final c = AuthCubit();
      final r = _signup(c, password: 'short', confirm: 'short');
      expect(r, AuthResult.failure);
      expect(c.state.error, 'Use at least 8 characters for your password.');
    });

    test('F02_A04 mismatch error; length check runs first', () {
      final c = AuthCubit();
      expect(_signup(c, confirm: 'different'), AuthResult.failure);
      expect(c.state.error, 'Passwords do not match. Please try again.');

      _signup(c, password: 'short', confirm: 'different');
      expect(c.state.error, 'Use at least 8 characters for your password.');
    });

    test('F02_A05 login has no length rule', () {
      final c = AuthCubit();
      final r = c.submitLogin(email: 'you@example.com', password: 'abc');
      expect(r, AuthResult.success);
      expect(c.state.error, isNull);
    });

    test('F02_A06 email, name and blank-password validation', () {
      for (final bad in ['', 'abc', 'a@b']) {
        expect(AuthCubit.isValidEmail(bad), isFalse, reason: "'$bad'");
        expect(
          AuthCubit().submitLogin(email: bad, password: 'pw'),
          AuthResult.failure,
        );
      }
      expect(AuthCubit.isValidEmail('you@example.com'), isTrue);

      expect(_signup(AuthCubit(), name: 'J'), AuthResult.failure);
      expect(_signup(AuthCubit(), name: '  '), AuthResult.failure);
      expect(_signup(AuthCubit(), name: 'Jo'), AuthResult.success);

      final blank = AuthCubit();
      expect(
        blank.submitLogin(email: 'you@example.com', password: ''),
        AuthResult.failure,
      );
      expect(blank.state.error, isNull, reason: 'blocked silently, no text');
      expect(blank.state.invalidFields, {AuthFieldName.password});
    });

    test('F02_A07 successful submits store the email', () {
      final forgot = AuthCubit();
      forgot.submitForgot(email: ' a@b.co ');
      expect(forgot.state.email, 'a@b.co');

      final signup = AuthCubit();
      _signup(signup, email: 's@x.io');
      expect(signup.state.email, 's@x.io');

      final login = AuthCubit();
      login.submitLogin(email: 'l@x.io', password: 'p');
      expect(login.state.email, 'l@x.io');
    });

    test('F02_A07 failed submit leaves the stored email untouched', () {
      final c = AuthCubit();
      c.submitForgot(email: 'keep@x.io');
      c.submitForgot(email: 'nope');
      expect(c.state.email, 'keep@x.io');
    });

    test('F02_A21 error clears on a later successful submit', () {
      final c = AuthCubit();
      _signup(c, password: 'short', confirm: 'short');
      expect(c.state.error, isNotNull);
      expect(_signup(c), AuthResult.success);
      expect(c.state.error, isNull);
    });
  });
}
