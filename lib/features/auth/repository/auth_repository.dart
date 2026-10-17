import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps Firebase Auth's Google sign-in flow (the project's default and
/// only wired provider — see tech-stack.md).
class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _injectedFirebaseAuth = firebaseAuth,
      _injectedGoogleSignIn = googleSignIn;

  // Resolved lazily so constructing an [AuthRepository]/[AuthCubit] never
  // touches Firebase unless a sign-in is actually attempted — tests that
  // only exercise the demo email/password forms never call Firebase.
  final FirebaseAuth? _injectedFirebaseAuth;
  final GoogleSignIn? _injectedGoogleSignIn;
  FirebaseAuth get _firebaseAuth => _injectedFirebaseAuth ?? FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => _injectedGoogleSignIn ?? GoogleSignIn();

  User? get currentUser => _firebaseAuth.currentUser;

  /// Signs in with Google, returning the signed-in [User]. Throws
  /// [StateError] if the user cancels the picker, or a [FirebaseAuthException]
  /// on a backend failure.
  Future<User> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw StateError('Google sign-in was cancelled.');
    }
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _firebaseAuth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) {
      throw StateError('Google sign-in did not return a user.');
    }
    return user;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
