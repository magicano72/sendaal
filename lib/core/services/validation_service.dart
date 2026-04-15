/// Validation service for form fields Register
class ValidationService {
  static const List<String> _commonEmailTlds = <String>[
    'com',
    'net',
    'org',
    'edu',
    'gov',
  ];

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

  static String normalizeEmail(String value) => value.trim().toLowerCase();

  /// Validate email using regex
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final normalized = normalizeEmail(value);
    final emailRegex = RegExp(
      r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
    );

    if (!emailRegex.hasMatch(normalized)) {
      return 'Please enter a valid email address';
    }

    final parts = normalized.split('@');
    if (parts.length != 2) {
      return 'Please enter a valid email address';
    }

    final localPart = parts[0];
    final domainPart = parts[1];
    final domainLabels = domainPart.split('.');

    if (localPart.startsWith('.') ||
        localPart.endsWith('.') ||
        localPart.contains('..') ||
        domainLabels.any(
          (label) =>
              label.isEmpty || label.startsWith('-') || label.endsWith('-'),
        )) {
      return 'Please enter a valid email address';
    }

    final correctedEmail = suggestEmailCorrection(normalized);
    if (correctedEmail != null) {
      return 'Please enter a valid email address. Did you mean $correctedEmail?';
    }

    return null;
  }

  static String? suggestEmailCorrection(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = normalizeEmail(value);
    final parts = normalized.split('@');
    if (parts.length != 2) {
      return null;
    }

    final domainLabels = parts[1].split('.');
    if (domainLabels.length < 2) {
      return null;
    }

    final tld = domainLabels.last;
    final correctedTld = _suggestTldCorrection(tld);
    if (correctedTld == null || correctedTld == tld) {
      return null;
    }

    domainLabels[domainLabels.length - 1] = correctedTld;
    return '${parts[0]}@${domainLabels.join('.')}';
  }

  static String? _suggestTldCorrection(String tld) {
    for (final commonTld in _commonEmailTlds) {
      if (_levenshteinDistance(tld, commonTld) == 1) {
        return commonTld;
      }
    }
    return null;
  }

  static int _levenshteinDistance(String source, String target) {
    if (source == target) {
      return 0;
    }
    if (source.isEmpty) {
      return target.length;
    }
    if (target.isEmpty) {
      return source.length;
    }

    final previousRow = List<int>.generate(target.length + 1, (i) => i);
    final currentRow = List<int>.filled(target.length + 1, 0);

    for (var i = 0; i < source.length; i++) {
      currentRow[0] = i + 1;
      for (var j = 0; j < target.length; j++) {
        final substitutionCost = source[i] == target[j] ? 0 : 1;
        currentRow[j + 1] = [
          currentRow[j] + 1,
          previousRow[j + 1] + 1,
          previousRow[j] + substitutionCost,
        ].reduce((a, b) => a < b ? a : b);
      }

      for (var j = 0; j < previousRow.length; j++) {
        previousRow[j] = currentRow[j];
      }
    }

    return previousRow.last;
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
