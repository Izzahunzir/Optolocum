import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create an account
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Log in
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Log out
  Future<void> signOut() {
    return _auth.signOut();
  }

  // Send password reset email
  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Verify ownership of the emailed reset link before changing the password.
  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String password,
  }) async {
    final resetEmail = await _auth.verifyPasswordResetCode(code);
    if (resetEmail.trim().toLowerCase() != email.trim().toLowerCase()) {
      throw FirebaseAuthException(
        code: 'invalid-action-code',
        message: 'This reset link belongs to a different email address.',
      );
    }
    await _auth.confirmPasswordReset(code: code, newPassword: password);
  }

  // Check whether a user is logged in
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }
}
