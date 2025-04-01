import 'package:vanishingtictactoe/shared/models/user_account.dart';
import 'package:vanishingtictactoe/features/auth/services/login_service.dart';
import 'package:vanishingtictactoe/features/auth/services/register_service.dart';
import 'package:vanishingtictactoe/features/auth/services/user_update_service.dart';

class AuthService {
  final LoginService _loginService = LoginService();
  final RegisterService _registerService = RegisterService();
  final UserUpdateService _userUpdateService = UserUpdateService();

  // Get current user account if logged in
  UserAccount? get currentUser => _loginService.currentUser;

  // Sign in with email and password
  Future<UserAccount> signInWithEmailAndPassword(String email, String password) async {
    return await _loginService.signInWithEmailAndPassword(email, password);
  }

  // Register with email and password
  Future<UserAccount> registerWithEmailAndPassword(String email, String password, String username) async {
    return await _registerService.registerWithEmailAndPassword(email, password, username);
  }

  // Sign out
  Future<void> signOut() async {
    await _loginService.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _userUpdateService.resetPasswordWithCustomAction(email);
  }

  // Update username
  Future<void> updateUsername(String newUsername) async {
    await _userUpdateService.updateUsername(newUsername);
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    await _userUpdateService.updateEmail(newEmail);
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    await _userUpdateService.updatePassword(newPassword);
  }

  // Stream of auth state changes
  Stream<UserAccount?> get authStateChanges => _loginService.authStateChanges;
}
