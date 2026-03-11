import 'package:sendaal/core/error/exceptions.dart';

/// Parses Directus API errors and returns user-friendly messages
class DirectusErrorParser {
  /// Parse ApiException and extract field error if it matches the target field
  /// Returns friendly message for field-level errors, null otherwise
  static String? parseFieldError(ApiException exception, String targetField) {
    try {
      final message = exception.message;

      // Check if it's a unique constraint error
      if (message.contains('has to be unique')) {
        if (targetField == 'username' && message.contains('username')) {
          return 'This username is already taken. Please choose another.';
        }
        if (targetField == 'email' && message.contains('email')) {
          return 'This email is already registered. Try logging in instead.';
        }
        if (targetField == 'phone' && message.contains('phone')) {
          return 'This phone number is already registered.';
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Parse ApiException and return a general user-friendly error message
  static String getGeneralErrorMessage(ApiException exception) {
    final message = exception.message;

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
