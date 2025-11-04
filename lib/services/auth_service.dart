import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // Sign in with email and password (returns credential)
  Future<UserCredential?> signInWithEmailAndPasswordAndReturnCredential(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if email already exists in Firebase
  Future<bool> emailExists(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final methods = await _auth.fetchSignInMethodsForEmail(normalizedEmail);
      final exists = methods.isNotEmpty;
      print('Firebase email check: $normalizedEmail exists = $exists, methods = $methods');
      return exists;
    } on FirebaseAuthException catch (e) {
      // If email doesn't exist, Firebase throws an exception
      // But if it does exist, it returns methods
      print('Firebase email check exception: ${e.code} - ${e.message}');
      if (e.code == 'invalid-email') {
        // Invalid email format, treat as doesn't exist
        return false;
      }
      // Other errors, assume doesn't exist to allow registration
      return false;
    } catch (e) {
      // If there's an error, assume email doesn't exist to allow registration
      print('Firebase email check error: $e');
      return false;
    }
  }

  // Handle Firebase Auth Exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}

