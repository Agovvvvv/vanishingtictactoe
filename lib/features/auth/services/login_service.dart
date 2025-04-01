import 'package:firebase_auth/firebase_auth.dart';
import 'package:vanishingtictactoe/shared/models/user_account.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/core/utils/firebase_error_handler.dart';
import 'package:vanishingtictactoe/core/utils/validation_utils.dart';

class LoginService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user account if logged in
  UserAccount? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    return UserAccount(
      id: user.uid,
      username: user.displayName ?? 'Player',
      email: user.email ?? '',
    );
  }

  // Sign in with email and password
  Future<UserAccount> signInWithEmailAndPassword(String email, String password) async {
  try {
    final sanitizedEmail = ValidationUtils.sanitizeInput(email).toLowerCase();
    if (sanitizedEmail.isEmpty) throw Exception('Email cannot be empty');
    
    final userCredential = await _auth.signInWithEmailAndPassword(email: sanitizedEmail, password: password);

    final user = userCredential.user;
    if (user == null) throw FirebaseAuthException(code: 'unknown', message: 'Login failed');
    
    return UserAccount(
      id: user.uid,
      username: user.displayName ?? 'Player',
      email: user.email ?? '',
    );
  } on FirebaseAuthException catch (e) {
    throw Exception(FirebaseErrorHandler.getAuthErrorMessage(e));
  } catch (e) {
    AppLogger.error('Error in signInWithEmailAndPassword: $e');
    throw Exception('An unexpected error occurred');
  }
}

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Stream of auth state changes
  Stream<UserAccount?> get authStateChanges {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return UserAccount(
        id: user.uid,
        username: user.displayName ?? 'Player',
        email: user.email ?? '',
      );
    });
  }
}