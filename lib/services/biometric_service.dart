import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:local_auth/local_auth.dart';

import 'auth_session_service.dart';

/// Biometric authentication result with detailed status
class BiometricAuthResult {
  final bool success;
  final BiometricStatus status;
  final String? errorMessage;

  const BiometricAuthResult({
    required this.success,
    required this.status,
    this.errorMessage,
  });

  factory BiometricAuthResult.success() =>
      const BiometricAuthResult(success: true, status: BiometricStatus.success);

  factory BiometricAuthResult.userCancel() => const BiometricAuthResult(
    success: false,
    status: BiometricStatus.userCanceled,
  );

  factory BiometricAuthResult.fallbackPressed() => const BiometricAuthResult(
    success: false,
    status: BiometricStatus.fallbackPressed,
  );

  factory BiometricAuthResult.notAvailable({String? reason}) =>
      BiometricAuthResult(
        success: false,
        status: BiometricStatus.notAvailable,
        errorMessage: reason,
      );

  factory BiometricAuthResult.error({required String message}) =>
      BiometricAuthResult(
        success: false,
        status: BiometricStatus.error,
        errorMessage: message,
      );
}

/// Biometric authentication flow status
enum BiometricStatus {
  success,
  userCanceled,
  fallbackPressed,
  notAvailable,
  error,
}

/// Production-level biometric service with fallback support
/// Handles:
/// - Device biometric capability detection
/// - Biometric authentication with proper error handling
/// - Biometric enrollment prompts (post-PIN setup)
/// - Optional toggle with confirmation
class BiometricService {
  BiometricService({AuthSessionService? sessionService})
    : _sessionService = sessionService ?? AuthSessionService.instance;

  final AuthSessionService _sessionService;
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometric authentication
  /// Returns false if:
  /// - Not iOS/Android platform
  /// - Device doesn't support biometrics
  /// - LocalAuth API fails
  Future<bool> isDeviceSupported() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isSupported;
    } catch (error) {
      debugPrint('[BiometricService] Device support check failed: $error');
      return false;
    }
  }

  /// Authenticate using biometric with detailed status
  /// Returns BiometricAuthResult with specific status
  /// Handles user cancellation separately from device errors
  Future<BiometricAuthResult> authenticate({
    String reason = 'Log in to Sendaal',
  }) async {
    if (!await isDeviceSupported()) {
      return BiometricAuthResult.notAvailable(
        reason: 'Biometric authentication not available on this device',
      );
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        return BiometricAuthResult.success();
      }

      // User canceled the biometric prompt
      return BiometricAuthResult.userCancel();
    } on PlatformException catch (error) {
      // Handle specific biometric errors
      if (error.code == 'NotAvailable') {
        return BiometricAuthResult.notAvailable(
          reason: 'Biometric scanner not available',
        );
      }
      if (error.code == 'PermanentlyLockedOut') {
        return BiometricAuthResult.error(
          message: 'Biometric authentication locked. Use PIN instead.',
        );
      }
      if (error.code == 'LockedOut') {
        return BiometricAuthResult.error(
          message: 'Too many failed attempts. Use PIN instead.',
        );
      }

      debugPrint(
        '[BiometricService] Biometric error: ${error.code} - ${error.message}',
      );
      return BiometricAuthResult.error(
        message: error.message ?? 'Authentication failed',
      );
    } catch (error) {
      debugPrint('[BiometricService] Unexpected biometric error: $error');
      return BiometricAuthResult.error(
        message: 'Unexpected error. Please use PIN instead.',
      );
    }
  }

  /// Enable biometric with confirmation
  /// Requires successful biometric authentication to enable
  /// Returns true if successfully enabled, false otherwise
  Future<bool> enableWithConfirmation() async {
    if (!await isDeviceSupported()) {
      return false;
    }

    final result = await authenticate(reason: 'Enable biometric login');
    if (result.success) {
      await _sessionService.secureStorage.write(
        key: kBiometricEnabled,
        value: 'true',
      );
      return true;
    }

    return false;
  }

  /// Disable biometric (no confirmation required)
  Future<void> disable() async {
    await _sessionService.secureStorage.write(
      key: kBiometricEnabled,
      value: 'false',
    );
  }

  /// Check if biometric is currently enabled
  Future<bool> isEnabled() async {
    return (await _sessionService.secureStorage.read(key: kBiometricEnabled)) ==
        'true';
  }

  /// Mark that user skipped biometric enrollment
  /// Used to not re-prompt during same session
  Future<void> markSkipped() async {
    await _sessionService.secureStorage.write(
      key: 'biometric_enrollment_skipped',
      value: DateTime.now().toIso8601String(),
    );
  }

  /// Check if user already skipped enrollment in this session
  Future<bool> hasSkippedEnrollment() async {
    final skipped = await _sessionService.secureStorage.read(
      key: 'biometric_enrollment_skipped',
    );
    return skipped != null;
  }

  /// Clear enrollment skip marker (when user revisits settings)
  Future<void> clearSkipMarker() async {
    await _sessionService.secureStorage.delete(
      key: 'biometric_enrollment_skipped',
    );
  }
}
