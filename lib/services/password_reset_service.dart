import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;

import 'api_client.dart';
import 'endpoint.dart';

/// Handles Directus forgot/reset password flow (email-based, no OTP).
class PasswordResetService {
  PasswordResetService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient.instance;

  // Use an https URL so email clients keep the link clickable.
  String _resetUrl = dotenv.env['PASSWORD_RESET_URL_ALLOW_LIST'] ?? '';

  final ApiClient _api;

  /// Request a reset email. Directus returns 204 even if the email is unknown.
  /// We swallow HTTP errors (401/404) to avoid leaking account existence.
  /// Network/timeouts still bubble up so the UI can show a retry message.
  Future<void> requestPasswordReset(String email) async {
    try {
      await _api.postPublic(
        Endpoints.requestPasswordReset,
        body: {'email': email, 'reset_url': _resetUrl},
      );
    } on ApiException catch (e) {
      // Network/timeouts come without an HTTP status code; surface those.
      if (e.statusCode == null) rethrow;
      // Any HTTP error (e.g., 401 allow-list) should still present success.
    }
  }

  /// Reset the password using the token from the deep link.
  /// Throws ApiException on 401/404 so the UI can show the invalid/expired message.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return _api.postPublic(
      Endpoints.resetPassword,
      body: {'token': token, 'password': newPassword},
    );
  }
}
