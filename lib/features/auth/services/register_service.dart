import 'package:firebase_auth/firebase_auth.dart';
import 'package:vanishingtictactoe/shared/models/user_account.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/core/utils/firebase_error_handler.dart';
import 'package:vanishingtictactoe/core/utils/validation_utils.dart';

class RegisterService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register with email and password
  Future<UserAccount> registerWithEmailAndPassword(String email, String password, String username) async {
    try {
      // Sanitize inputs
      final sanitizedEmail = ValidationUtils.sanitizeInput(email).toLowerCase();
      final sanitizedUsername = ValidationUtils.sanitizeInput(username);

      // Additional validation
      if (sanitizedUsername.isEmpty || sanitizedEmail.isEmpty) {
        throw Exception("Invalid input data");
      }
      final result = await _auth.createUserWithEmailAndPassword(
        email: sanitizedEmail,
        password: password,  // Don't sanitize password as it would affect its security
      );
      final user = result.user;
      if (user == null) throw FirebaseAuthException(code: 'unknown', message: 'Registration failed');

      // Update display name with sanitized username
      await user.updateDisplayName(sanitizedUsername);

      return UserAccount(
        id: user.uid,
        username: sanitizedUsername,
        email: sanitizedEmail,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrorHandler.getAuthErrorMessage(e));
    } catch (e) {
      AppLogger.error('Error in registration: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }
}