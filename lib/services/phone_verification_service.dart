import '../core/error/exceptions.dart' as core_exceptions;
import 'api_client.dart' hide ApiException;
import 'endpoint.dart';

/// Handles OTP lifecycle for phone number verification via Directus extension.
class PhoneVerificationService {
  final ApiClient _api;

  PhoneVerificationService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient.instance;

  /// Request a verification code to be sent to the given phone number.
  Future<PhoneVerificationSession> requestVerification({
    required String phoneNumber,
    required String countryCode,
  }) async {
    final response = await _api.postPublic(
      Endpoints.requestPhoneVerification,
      body: {'phone_number': phoneNumber, 'country_code': countryCode},
    );
    final data = _unwrapData(response);
    return PhoneVerificationSession.fromJson(data);
  }

  /// Verify an OTP code. Returns true on success.
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    await _api.postPublic(
      Endpoints.verifyPhoneOtp,
      body: {'phone_number': phoneNumber, 'otp': otp},
    );
    return true;
  }

  /// Resend the OTP to the same phone number.
  Future<PhoneVerificationSession> resendOtp({
    required String phoneNumber,
  }) async {
    final response = await _api.postPublic(
      Endpoints.resendPhoneOtp,
      body: {'phone_number': phoneNumber},
    );
    final data = _unwrapData(response);
    return PhoneVerificationSession.fromJson(data);
  }

  /// Retrieve current verification status; useful for restoring OTP screen.
  Future<PhoneVerificationSession?> status(String phoneNumber) async {
    final response = await _api.getPublic(
      Endpoints.phoneVerificationStatus,
      queryParams: {'phone_number': phoneNumber},
    );
    final data = _unwrapData(response);
    if (data.isEmpty) return null;
    return PhoneVerificationSession.fromJson(data);
  }

  Map<String, dynamic> _unwrapData(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response['data'] as Map);
      }
      return Map<String, dynamic>.from(response);
    }
    throw core_exceptions.ApiException(message: 'Unexpected response from server.');
  }
}

/// Simple in-memory representation of an OTP session.
class PhoneVerificationSession {
  final String phoneNumber;
  final String countryCode;
  final int expiresIn;
  final int canResendAfter;

  const PhoneVerificationSession({
    required this.phoneNumber,
    required this.countryCode,
    required this.expiresIn,
    required this.canResendAfter,
  });

  factory PhoneVerificationSession.fromJson(Map<String, dynamic> json) {
    return PhoneVerificationSession(
      phoneNumber: json['phone_number']?.toString() ?? '',
      countryCode: json['country_code']?.toString() ?? '',
      expiresIn: _asInt(json['expires_in']),
      canResendAfter: _asInt(json['can_resend_after']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }
}
