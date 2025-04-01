class ValidationUtils {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }
  
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.length > 30) {
      return 'Username must be less than 30 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }
  
  static String sanitizeInput(String input) {
    // Remove any HTML tags
    input = input.replaceAll(RegExp(r"<[^>]*>"), "");
    // Remove any script tags and their contents
    input = input.replaceAll(RegExp(r"<script[^>]*>([\s\S]*?)</script>"), "");
    // Remove any potential SQL injection patterns - handle each character separately
    input = input.replaceAll("'", "")
                 .replaceAll("\"", "")
                 .replaceAll(";", "")
                 .replaceAll("--", "");
    // Trim whitespace
    input = input.trim();
    return input;
  }
}