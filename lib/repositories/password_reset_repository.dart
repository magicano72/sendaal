import '../services/password_reset_service.dart';

/// Repository wrapper for password reset flows to keep UI/service decoupled.
class PasswordResetRepository {
  PasswordResetRepository({PasswordResetService? service})
    : _service = service ?? PasswordResetService();

  final PasswordResetService _service;

  Future<void> requestPasswordReset(String email) =>
      _service.requestPasswordReset(email);

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) =>
      _service.resetPassword(token: token, newPassword: newPassword);
}
