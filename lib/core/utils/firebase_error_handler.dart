import 'package:firebase_auth/firebase_auth.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';

class FirebaseErrorHandler {
  static String getAuthErrorMessage(FirebaseAuthException e) {
    AppLogger.error('Firebase Auth Error Code: ${e.code}');
    
    switch (e.code) {
      // Authentication errors
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-email':
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'auth/invalid-email':
      case 'auth/user-not-found':
      case 'auth/wrong-password':
        return 'Email or password are not valid';
      
      // Account status errors
      case 'user-disabled':
      case 'auth/user-disabled':
        return 'This account has been disabled';
      
      // Rate limiting errors
      case 'too-many-requests':
      case 'auth/too-many-requests':
        return 'Too many attempts. Please try again later';
      
      // Registration errors
      case 'email-already-in-use':
      case 'auth/email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
      case 'auth/weak-password':
        return 'Please use a stronger password';
      case 'operation-not-allowed':
      case 'auth/operation-not-allowed':
        return 'This operation is not available at this time';
      
      // Network errors
      case 'network-request-failed':
      case 'auth/network-request-failed':
        return 'Network error. Please check your connection';
      
      // Default case
      default:
        return 'An error occurred. Please try again';
    }
  }
}