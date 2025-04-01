import 'package:firebase_auth/firebase_auth.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/core/utils/firebase_error_handler.dart';
import 'package:vanishingtictactoe/core/utils/validation_utils.dart';

class UserUpdateService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      final sanitizedEmail = ValidationUtils.sanitizeInput(newEmail).toLowerCase();
      
      // Validate email is not empty
      if (sanitizedEmail.isEmpty) {
        throw Exception('Email cannot be empty');
      }
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not signed in');
      
      await user.verifyBeforeUpdateEmail(sanitizedEmail);
    } on FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrorHandler.getAuthErrorMessage(e));
    } catch (e) {
      AppLogger.error('Error in updateEmail: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      // Password is not sanitized as it would affect its security
      if (newPassword.isEmpty) {
        throw Exception('Password cannot be empty');
      }
      
      // Check for minimum password strength (same as registration)
      if (newPassword.length < 6) {
        throw Exception('Please use a stronger password');
      }
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not signed in');
      
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrorHandler.getAuthErrorMessage(e));
    } catch (e) {
      AppLogger.error('Error in updatePassword: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  // Update username
  Future<void> updateUsername(String newUsername) async {
    try {
      final sanitizedUsername = ValidationUtils.sanitizeInput(newUsername);
      
      // Validate username is not empty
      if (sanitizedUsername.isEmpty) {
        throw Exception('Username cannot be empty');
      }
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not signed in');
      
      await user.updateDisplayName(sanitizedUsername);
    } catch (e) {
      AppLogger.error('Error in updateUsername: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  // Reset password with custom action handler
  Future<void> resetPasswordWithCustomAction(String email, {String? continueUrl}) async {
    try {
      final sanitizedEmail = ValidationUtils.sanitizeInput(email).toLowerCase();
      
      if (sanitizedEmail.isEmpty) {
        throw Exception("Email cannot be empty");
      }
      
      if (sanitizedEmail == "nicdueperdue@gmail.com") {
        throw Exception("Ventu sei un coglione");
      }
      
      // Set up ActionCodeSettings for custom handling
      ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        url: continueUrl ?? 'https://vanishing-tic-tac-toe.firebaseapp.com/__/auth/action?mode=action&oobCode=code',
        // This must be true for mobile apps
        handleCodeInApp: true,
        // // Set to true if you want to allow the user to install your app if they don't have it
        // androidPackageName: 'com.yourdomain.vanishingtictactoe',
        // androidInstallApp: true,
        // // Minimum version of your Android app
        // androidMinimumVersion: '12',
        // // iOS bundle ID
        // iOSBundleId: 'com.yourdomain.vanishingtictactoe',
      );
      
      await _auth.sendPasswordResetEmail(
        email: sanitizedEmail,
        actionCodeSettings: actionCodeSettings,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrorHandler.getAuthErrorMessage(e));
    } catch (e) {
      AppLogger.error('Error in resetPasswordWithCustomAction: $e');
      throw Exception('An unexpected error occurred');
    }
  }
}