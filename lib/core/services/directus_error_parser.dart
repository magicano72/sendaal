import 'package:sendaal/core/error/exceptions.dart';

/// Parses Directus API errors and returns user-friendly messages
class DirectusErrorParser {
  /// Parse ApiException and extract field error if it matches the target field
  /// Returns friendly message for field-level errors, null otherwise
  static String? parseFieldError(ApiException exception, String targetField) {
    try {
      final message = exception.message;
      final lowerMessage = message.toLowerCase();
      bool mentionsField(String field) => lowerMessage.contains(field);
      bool mentionsValidEmailMessage() =>
          lowerMessage.contains('valid email') ||
          lowerMessage.contains('email address');
      bool mentionsValidPhoneMessage() =>
          lowerMessage.contains('valid phone') ||
          lowerMessage.contains('phone number');
      bool mentionsValidationFailure() =>
          lowerMessage.contains('validation failed') ||
          lowerMessage.contains('failed validation') ||
          lowerMessage.contains('has to be a valid') ||
          lowerMessage.contains('must be a valid') ||
          lowerMessage.contains('should be a valid');

      final isUniqueViolation =
          lowerMessage.contains('has to be unique') ||
          lowerMessage.contains('already been used') ||
          lowerMessage.contains('already exists') ||
          lowerMessage.contains('record_not_unique');

      // Uniqueness errors (duplicate username/email/phone)
      if (isUniqueViolation) {
        if (targetField == 'username' && mentionsField('username')) {
          return 'This username is already taken.';
        }
        if (targetField == 'email' && mentionsField('email')) {
          return 'Email is already registered.';
        }
        if (targetField == 'phone' && mentionsField('phone')) {
          return 'This phone number is already registered.';
        }
      }

      // Field-level validation errors (e.g., invalid email format)
      if (mentionsValidationFailure()) {
        if (targetField == 'email' && mentionsField('email')) {
          return 'Please enter a valid email address.';
        }
        if (targetField == 'phone' && mentionsField('phone')) {
          return 'Please enter a valid phone number.';
        }
        if (targetField == 'username' && mentionsField('username')) {
          return 'Username is not valid. Please adjust and try again.';
        }
      }

      // Explicit email validity phrases even without "validation failed"
      if (targetField == 'email' &&
          mentionsField('email') &&
          mentionsValidEmailMessage()) {
        return 'Please enter a valid email address.';
      }
      if (targetField == 'phone' &&
          mentionsField('phone') &&
          mentionsValidPhoneMessage()) {
        return 'Please enter a valid phone number.';
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Parse ApiException and return a general user-friendly error message
  static String getGeneralErrorMessage(ApiException exception) {
    final message = exception.message;
    final lowerMessage = message.toLowerCase();

    // Unique constraint friendly mapping
    if (message.contains('has to be unique')) {
      if (message.contains('email')) {
        return 'Email is already registered.';
      }
      if (message.contains('phone')) {
        return 'This phone number is already registered.';
      }
      if (message.contains('username')) {
        return 'This username is already taken.';
      }
      return 'This account already exists.';
    }

    // Handle specific error types
    if (message.contains('No internet connection')) {
      return 'No internet connection. Please check your network.';
    }

    if (message.contains('Request timed out')) {
      return 'Request timed out. Please try again.';
    }

    if (message.contains('Unauthorized') || message.contains('credentials')) {
      return 'Email or password is incorrect. Please try again.';
    }

    if (message.contains('already been used') ||
        message.contains('already exists')) {
      return 'Account already exists. Please try logging in.';
    }

    if (message.contains('RECORD_NOT_UNIQUE')) {
      return 'This account already exists. Please try a different email or username.';
    }

    // Validation errors for specific fields
    if (lowerMessage.contains('validation failed') ||
        lowerMessage.contains('failed validation') ||
        lowerMessage.contains('has to be a valid') ||
        lowerMessage.contains('must be a valid') ||
        lowerMessage.contains('should be a valid')) {
      if (lowerMessage.contains('email')) {
        return 'Please enter a valid email address.';
      }
      if (lowerMessage.contains('phone')) {
        return 'Please enter a valid phone number.';
      }
      if (lowerMessage.contains('username')) {
        return 'Username is not valid. Please adjust and try again.';
      }
      return 'One or more fields are invalid. Please check your inputs.';
    }

    // Direct "valid email" phrase without explicit validation wording
    if (lowerMessage.contains('valid email')) {
      return 'Please enter a valid email address.';
    }

    // Default generic message
    return 'Something went wrong. Please try again.';
  }

  /// Check if error is a specific field uniqueness error
  static bool isFieldUniqueError(ApiException exception, String fieldName) {
    try {
      final message = exception.message;
      return message.contains('has to be unique') &&
          message.contains(fieldName);
    } catch (_) {
      return false;
    }
  }
}
