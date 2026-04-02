/// Validation service for form fields Register
class ValidationService {
  /// Validate name - not whitespace only, minimum 4 characters for first name
  static String? validateName(String? value, {int minLength = 2}) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.trim().isEmpty) {
      return 'Name cannot be whitespace only';
    }
    if (value.length < minLength) {
      return 'Name must be at least $minLength characters';
    }
    return null;
  }

  /// Validate username - not empty, basic format
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.trim().isEmpty) {
      return 'Username cannot be whitespace only';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, underscore, and hyphen';
    }
    return null;
  }

  /// Validate email using regex
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate international phone number (expects leading + with country code).
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^\\+?[0-9]{7,}$').hasMatch(cleaned)) {
      return 'Enter a valid phone number with country code';
    }
    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecialChar = RegExp(r'[!@#$%^&*]').hasMatch(value);

    if (!hasUppercase) {
      return 'Password must contain an uppercase letter';
    }
    if (!hasLowercase) {
      return 'Password must contain a lowercase letter';
    }
    if (!hasNumber) {
      return 'Password must contain a number';
    }
    if (!hasSpecialChar) {
      return 'Password must contain a special character (!@#\$%^&*)';
    }
    return null;
  }

  /// Get visual feedback for password strength requirements
  static Map<String, bool> getPasswordRequirements(String password) {
    return {
      'At least 8 characters': password.length >= 8,
      'Contains uppercase letter': RegExp(r'[A-Z]').hasMatch(password),
      'Contains lowercase letter': RegExp(r'[a-z]').hasMatch(password),
      'Contains number': RegExp(r'[0-9]').hasMatch(password),
      'Contains special character (!@#\$%^&*)': RegExp(
        r'[!@#$%^&*]',
      ).hasMatch(password),
    };
  }
}
