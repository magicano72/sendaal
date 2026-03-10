import 'exceptions.dart';

class AppError {
  final String message;
  final String code;
  final dynamic originalError;

  AppError({
    required this.message,
    this.code = 'UNKNOWN_ERROR',
    this.originalError,
  });

  factory AppError.fromException(Exception exception) {
    if (exception is ApiException) {
      return AppError(
        message: exception.message,
        code: 'API_ERROR',
        originalError: exception,
      );
    } else if (exception is NetworkException) {
      return AppError(
        message: exception.message,
        code: 'NETWORK_ERROR',
        originalError: exception,
      );
    } else if (exception is ValidationException) {
      return AppError(
        message: exception.message,
        code: 'VALIDATION_ERROR',
        originalError: exception,
      );
    } else if (exception is AuthException) {
      return AppError(
        message: exception.message,
        code: 'AUTH_ERROR',
        originalError: exception,
      );
    } else if (exception is StorageException) {
      return AppError(
        message: exception.message,
        code: 'STORAGE_ERROR',
        originalError: exception,
      );
    }

    return AppError(message: exception.toString(), originalError: exception);
  }

  String get userFriendlyMessage {
    switch (code) {
      case 'API_ERROR':
        return 'Something went wrong. Please try again.';
      case 'NETWORK_ERROR':
        return 'No internet connection. Please check your network.';
      case 'VALIDATION_ERROR':
        return 'Please check your input and try again.';
      case 'AUTH_ERROR':
        return 'Authentication failed. Please log in again.';
      case 'STORAGE_ERROR':
        return 'Failed to save data locally.';
      default:
        return message;
    }
  }
}

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return 'Unauthorized. Please log in again.';
      } else if (error.statusCode == 403) {
        return 'You do not have permission to perform this action.';
      } else if (error.statusCode == 404) {
        return 'The requested resource was not found.';
      } else if (error.statusCode == 500) {
        return 'Server error. Please try again later.';
      }
      return error.message;
    } else if (error is NetworkException) {
      return 'Network error: ${error.message}';
    } else if (error is ValidationException) {
      return error.message;
    } else if (error is AuthException) {
      return error.message;
    } else if (error is StorageException) {
      return error.message;
    }
    return 'An unexpected error occurred.';
  }
}
