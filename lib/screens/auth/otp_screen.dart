import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/error/exceptions.dart';
import '../../core/router/app_router.dart';
import '../../core/services/validation_service.dart';
import '../../core/theme/text_style.dart';
import '../../providers/auth_provider.dart';
import '../../services/phone_verification_service.dart';
import '../../widgets/app_snackbar.dart';
import 'otp_args.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final OtpFlowArgs args;

  const OtpScreen({super.key, required this.args});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _resendCooldownSeconds = 600; // 10 minutes
  late final List<TextEditingController> _digitCtrls;
  late final List<FocusNode> _digitNodes;
  final _verificationService = PhoneVerificationService();

  late PhoneVerificationSession _session;
  late int _remainingSeconds;
  late int _resendSeconds;
  Timer? _expiryTimer;
  Timer? _resendTimer;

  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _digitCtrls = List.generate(4, (_) => TextEditingController());
    _digitNodes = List.generate(4, (_) => FocusNode());
    _session = widget.args.session;
    _remainingSeconds = _session.expiresIn;
    _resendSeconds = _resendCooldownSeconds;
    _startTimers();
  }

  @override
  void dispose() {
    for (final c in _digitCtrls) {
      c.dispose();
    }
    for (final f in _digitNodes) {
      f.dispose();
    }
    _expiryTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startTimers() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds--);
      }
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds <= 0) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  String _collectOtp() => _digitCtrls.map((c) => c.text.trim()).join();

  void _handleDigitChange(int index, String value) {
    if (value.length > 1) {
      // Only keep the last char typed/pasted
      _digitCtrls[index].text = value.substring(value.length - 1);
      _digitCtrls[index].selection = TextSelection.collapsed(offset: 1);
    }

    if (value.isNotEmpty && index < _digitNodes.length - 1) {
      _digitNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _digitNodes[index - 1].requestFocus();
    }

    setState(() {
      _error = null;
    });
  }

  String _maskPhone(String phone) {
    if (phone.isEmpty) return '';
    final clean = phone.replaceAll(RegExp(r'\s'), '');
    if (clean.length <= 4) return clean;
    final last4 = clean.substring(clean.length - 4);
    return '${clean.substring(0, 2)} ••• ••• $last4';
  }

  Future<void> _verify() async {
    final otp = _collectOtp();
    if (otp.length < 4) {
      setState(() => _error = 'Enter the 4-digit code');
      return;
    }
    if (_remainingSeconds <= 0) {
      setState(() => _error = 'Code expired. Please resend a new one.');
      return;
    }

    setState(() {
      _error = null;
      _isVerifying = true;
    });

    try {
      final payload = widget.args.registerPayload;
      final emailError = ValidationService.validateEmail(payload.email);
      if (emailError != null) {
        final message = '$emailError Please go back and correct your email.';
        setState(() => _error = message);
        if (mounted) {
          AppSnackBar.error(context, message);
        }
        return;
      }

      await _verificationService.verifyOtp(
        phoneNumber: _session.phoneNumber.isNotEmpty
            ? _session.phoneNumber
            : widget.args.registerPayload.phoneNumber,
        otp: otp,
      );

      final success = await ref
          .read(authProvider.notifier)
          .register(
            email: ValidationService.normalizeEmail(payload.email),
            password: payload.password,
            username: payload.username,
            firstName: payload.firstName,
            phoneNumber: _session.phoneNumber.isNotEmpty
                ? _session.phoneNumber
                : payload.phoneNumber,
            countryCode: payload.countryCode,
          );

      if (!mounted) return;

      if (success) {
        AppSnackBar.success(
          context,
          'Phone verified successfully. Please log in.',
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      } else {
        final authError =
            ref.read(authProvider).error ??
            'Registration failed after verification.';
        setState(() => _error = authError);
        AppSnackBar.error(context, authError);
      }
    } on ApiException catch (e) {
      final msg = _mapOtpError(e);
      setState(() => _error = msg);
      if (mounted) AppSnackBar.error(context, msg);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
      if (mounted) {
        AppSnackBar.error(context, 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _error = null;
    });
    try {
      final session = await _verificationService.resendOtp(
        phoneNumber: _session.phoneNumber.isNotEmpty
            ? _session.phoneNumber
            : widget.args.registerPayload.phoneNumber,
      );
      setState(() {
        _session = session;
        _remainingSeconds = session.expiresIn;
        _resendSeconds = _resendCooldownSeconds;
      });
      _startTimers();
      if (mounted) {
        AppSnackBar.info(
          context,
          'A new code was sent to ${session.phoneNumber}',
        );
      }
    } on ApiException catch (e) {
      final msg = _mapOtpError(e);
      setState(() => _error = msg);
      if (mounted) AppSnackBar.error(context, msg);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String _mapOtpError(ApiException ex) {
    switch (ex.statusCode) {
      case 400:
        return 'Invalid OTP. Please try again.';
      case 404:
        return 'No pending verification. Please request a new code.';
      case 409:
        return 'This phone number is already verified. Try logging in.';
      case 429:
        return 'Too many attempts. Please wait and try again.';
      default:
        return ex.message;
    }
  }

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final phoneToShow = _session.phoneNumber.isNotEmpty
        ? _session.phoneNumber
        : widget.args.registerPayload.phoneNumber;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FB),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.3, -0.4),
              radius: 1.2,
              colors: [Color(0xFFEFF4FB), Color(0xFFF6F9FD)],
              stops: [0.2, 1],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 72.r,
                      width: 72.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F2FC),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 34.r,
                        color: const Color(0xFF0B63CE),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Verification Code',
                      style: TextStyles.h1Semi.copyWith(
                        color: const Color(0xFF0F192A),
                        fontSize: 22.sp,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Enter the 4-digit code sent to your\nphone number ${_maskPhone(phoneToShow)}',
                      textAlign: TextAlign.center,
                      style: TextStyles.bodySmall.copyWith(
                        color: const Color(0xFF6B7380),
                        height: 1.5,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) {
                        return SizedBox(
                          width: 64.r,
                          height: 64.r,
                          child: TextField(
                            controller: _digitCtrls[index],
                            focusNode: _digitNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: TextStyles.h2Semi.copyWith(
                              fontSize: 24.sp,
                              color: const Color(0xFF0F192A),
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE3E8F0),
                                  width: 1.6,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0B63CE),
                                  width: 2,
                                ),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (val) => _handleDigitChange(index, val),
                          ),
                        );
                      }),
                    ),
                    if (_error != null) ...[
                      SizedBox(height: 10.h),
                      Text(
                        _error!,
                        style: TextStyles.captionMedium.copyWith(
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                    SizedBox(height: 26.h),
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B63CE),
                          disabledBackgroundColor: const Color(
                            0xFF0B63CE,
                          ).withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          elevation: 0,
                        ),
                        child: _isVerifying
                            ? SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Verify',
                                style: TextStyles.bodyBold.copyWith(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: TextStyles.bodySmall.copyWith(
                            color: const Color(0xFF8A94A6),
                            fontSize: 14.sp,
                          ),
                        ),
                        TextButton(
                          onPressed: (_resendSeconds > 0 || _isResending)
                              ? null
                              : _resend,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: _isResending
                              ? SizedBox(
                                  width: 16.r,
                                  height: 16.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _resendSeconds > 0
                                      ? 'Resend in ${_formatSeconds(_resendSeconds)}'
                                      : 'Resend Code',
                                  style: TextStyles.bodyBold.copyWith(
                                    color: const Color(0xFF0B63CE),
                                    fontSize: 14.sp,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
