/// Custom exception for API errors
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? response;

  ApiException({this.statusCode, required this.message, this.response});

  @override
  String toString() => message;
}

/// Custom exception for network errors
class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => message;
}

/// Custom exception for validation errors
class ValidationException implements Exception {
  final String message;
  final Map<String, String>? errors;

  ValidationException({required this.message, this.errors});

  @override
  String toString() => message;
}

/// Custom exception for local storage errors
class StorageException implements Exception {
  final String message;

  StorageException(this.message);

  @override
  String toString() => message;
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}
