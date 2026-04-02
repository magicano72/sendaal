import '../../services/phone_verification_service.dart';

class RegisterPayload {
  final String email;
  final String password;
  final String username;
  final String firstName;
  final String phoneNumber;
  final String countryCode;

  const RegisterPayload({
    required this.email,
    required this.password,
    required this.username,
    required this.firstName,
    required this.phoneNumber,
    required this.countryCode,
  });
}

class OtpFlowArgs {
  final RegisterPayload registerPayload;
  final PhoneVerificationSession session;

  const OtpFlowArgs({
    required this.registerPayload,
    required this.session,
  });
}
