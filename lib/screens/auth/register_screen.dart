import 'package:Sendaal/widgets/app_snackbar.dart';
import 'package:Sendaal/widgets/app_widgets.dart' show ErrorBanner;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../core/error/exceptions.dart';
import '../../core/router/app_router.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/directus_error_parser.dart';
import '../../core/services/validation_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../providers/auth_provider.dart';
import '../../services/phone_verification_service.dart';
import '../../services/user_service.dart';
import 'otp_args.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _firstNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _agreedToTerms = false;
  bool _isRequestingOtp = false;
  bool _isCheckingAvailability = false;
  final _formKey = GlobalKey<FormState>();
  String? _formError; // non-field specific API errors
  final _userService = UserService();

  // Field-level error tracking for API errors
  String? _usernameError;
  String? _emailError;
  String? _phoneError;
  String _phoneNumber = '';
  String _countryCode = '+20';
  int _phoneMaxLength = 10; // default for EG; updated when country changes
  int _phoneMinLength = 8;
  String? _lastEmailChecked;
  String? _lastUsernameChecked;
  String? _lastPhoneChecked;
  UserAvailability? _lastAvailability;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Clear previous API errors
    setState(() {
      _usernameError = null;
      _emailError = null;
      _phoneError = null;
      _formError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    if (_phoneNumber.isEmpty) {
      setState(() => _phoneError = 'Phone number is required');
      return;
    }

    if (!_agreedToTerms) {
      AppSnackBar.error(
        context,
        'Please agree to the Terms of Service and Privacy Policy.',
      );

      return;
    }

    // Check internet connection before API call
    final connectivity = ConnectivityService();
    final hasInternet = await connectivity.hasInternetConnection();

    if (!hasInternet) {
      if (mounted) {
        AppSnackBar.error(
          context,
          "No internet connection. Please try again later.",
        );
      }
      return;
    }

    // Backend uniqueness check before sending OTP
    final email = ValidationService.normalizeEmail(_emailCtrl.text);
    final username = _usernameCtrl.text.trim();
    final phone = _phoneNumber.trim();

    final availability = await _checkAvailability(
      email: email,
      username: username,
      phoneNumber: phone,
    );

    if (availability == null) {
      // Network/API error already handled with form error/snackbar
      return;
    }

    if (!availability.isAllFree) {
      setState(() {
        if (availability.emailTaken) {
          _emailError = 'Email already registered';
        }
        if (availability.phoneTaken) {
          _phoneError = 'Phone number already used';
        }
        if (availability.usernameTaken) {
          _usernameError = 'Username already taken';
        }
      });
      return; // Do not request OTP
    }

    final payload = RegisterPayload(
      email: email,
      password: _passwordCtrl.text,
      username: _usernameCtrl.text.trim(),
      firstName: _firstNameCtrl.text.trim(),
      phoneNumber: _phoneNumber,
      countryCode: _countryCode,
    );

    final phoneService = PhoneVerificationService();

    try {
      setState(() => _isRequestingOtp = true);
      final session = await phoneService.requestVerification(
        phoneNumber: _phoneNumber,
        countryCode: _countryCode,
      );

      if (!mounted) return;

      AppSnackBar.success(context, 'Verification code sent to $_phoneNumber');

      Navigator.pushNamed(
        context,
        AppRoutes.otp,
        arguments: OtpFlowArgs(registerPayload: payload, session: session),
      );
    } on ApiException catch (e) {
      final apiEx = ApiException(message: e.message, statusCode: e.statusCode);

      _usernameError = null;
      _emailError = null;
      _phoneError = DirectusErrorParser.parseFieldError(apiEx, 'phone_number');

      if (_phoneError != null) {
        setState(() {});
        _formKey.currentState?.validate();
      } else {
        final friendly = _mapOtpError(e);
        setState(() => _formError = friendly);
        if (mounted) AppSnackBar.error(context, friendly);
      }
    } catch (e) {
      setState(() => _formError = 'Something went wrong. Please try again.');
      if (mounted) {
        AppSnackBar.error(context, 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isRequestingOtp = false);
    }
  }

  Future<UserAvailability?> _checkAvailability({
    required String email,
    required String username,
    required String phoneNumber,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedUsername = username.trim();
    final trimmedPhone = phoneNumber.trim();

    if (_lastEmailChecked == trimmedEmail &&
        _lastUsernameChecked == trimmedUsername &&
        _lastPhoneChecked == trimmedPhone &&
        _lastAvailability != null) {
      return _lastAvailability;
    }

    setState(() {
      _isCheckingAvailability = true;
      _formError = null;
    });

    try {
      final availability = await _userService.checkAvailability(
        email: trimmedEmail,
        username: trimmedUsername,
        phoneNumber: trimmedPhone,
      );
      setState(() {
        _lastEmailChecked = trimmedEmail;
        _lastUsernameChecked = trimmedUsername;
        _lastPhoneChecked = trimmedPhone;
        _lastAvailability = availability;
      });
      return availability;
    } on ApiException catch (e) {
      setState(() {
        _formError = e.message;
      });
      if (mounted) {
        AppSnackBar.error(
          context,
          e.message.isNotEmpty
              ? e.message
              : 'Could not validate availability. Please try again.',
        );
      }
      return null;
    } catch (e) {
      setState(() {
        _formError = 'Could not validate availability. Please try again.';
      });
      if (mounted) {
        AppSnackBar.error(
          context,
          'Could not validate availability. Please try again.',
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAvailability = false;
        });
      }
    }
  }

  String _mapOtpError(ApiException exception) {
    switch (exception.statusCode) {
      case 400:
        return 'Invalid phone number. Please check and try again.';
      case 404:
        return 'No pending verification. Please try again.';
      case 409:
        return 'This phone number is already verified. Try logging in.';
      case 429:
        return 'Too many attempts. Please wait before retrying.';
      default:
        return DirectusErrorParser.getGeneralErrorMessage(exception);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isSubmitting =
        auth.isRegisterLoading || _isRequestingOtp || _isCheckingAvailability;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable content ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
                child: Column(
                  children: [
                    // White card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 20.h,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Headline ───────────────────────────────────
                            Text(
                              'Join Sendaal',
                              style: TextStyles.h1Semi.copyWith(
                                color: const Color(0xFF1A1A2E),
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              'Fill in your details to get started with\nyour new account.',
                              style: TextStyles.bodySmall.copyWith(
                                color: const Color(0xFF8A94A6),
                                height: 1.5,
                              ),
                            ),

                            SizedBox(height: 20.h),

                            // ── First Name ─────────────────────────────────
                            _FieldLabel(label: 'Full Name'),
                            SizedBox(height: 8.h),
                            TextFormField(
                              controller: _firstNameCtrl,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              style: TextStyles.bodySmall.copyWith(
                                fontSize: 15.sp,
                                color: const Color(0xFF1A1A2E),
                              ),
                              decoration: _inputDecoration(hint: 'e.g. John'),
                              validator: (v) => ValidationService.validateName(
                                v,
                                minLength: 2,
                              ),
                            ),

                            SizedBox(height: 12.h),

                            // ── Username ───────────────────────────────────
                            _FieldLabel(label: 'Username'),
                            SizedBox(height: 8.h),
                            TextFormField(
                              controller: _usernameCtrl,
                              style: TextStyles.bodySmall.copyWith(
                                fontSize: 15.sp,
                                color: const Color(0xFF1A1A2E),
                              ),
                              decoration: _inputDecoration(
                                hint: 'Enter your username',
                                errorText: _usernameError,
                              ),
                              validator: (v) =>
                                  ValidationService.validateUsername(v),
                            ),

                            SizedBox(height: 12.h),

                            // ── Email ──────────────────────────────────────
                            _FieldLabel(label: 'Email Address'),
                            SizedBox(height: 8.h),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyles.bodySmall.copyWith(
                                fontSize: 15.sp,
                                color: const Color(0xFF1A1A2E),
                              ),
                              decoration: _inputDecoration(
                                hint: 'email@example.com',
                                errorText: _emailError,
                              ),
                              validator: (v) =>
                                  ValidationService.validateEmail(v),
                            ),

                            SizedBox(height: 12.h),

                            // ── Phone ──────────────────────────────────────
                            _FieldLabel(label: 'Phone Number'),
                            SizedBox(height: 8.h),
                            IntlPhoneField(
                              initialCountryCode: 'EG',
                              disableLengthCheck:
                                  false, // respect per-country lengths
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(
                                  _phoneMaxLength,
                                ),
                              ],
                              decoration: _inputDecoration(
                                hint: 'Enter phone number',
                                errorText: _phoneError,
                              ),
                              onChanged: (phone) {
                                setState(() {
                                  _phoneError = null;
                                  _phoneNumber = phone.completeNumber
                                      .replaceAll(' ', '');
                                  _countryCode = phone.countryCode;
                                });
                              },
                              onCountryChanged: (country) {
                                setState(() {
                                  _phoneError = null;
                                  _phoneMaxLength =
                                      country.maxLength ?? _phoneMaxLength;
                                  _phoneMinLength =
                                      country.minLength ?? _phoneMinLength;
                                  _countryCode = '+${country.dialCode}';
                                });
                              },
                              validator: (phone) {
                                if (_phoneError != null) return _phoneError;
                                if (phone == null) {
                                  return 'Phone number is required';
                                }

                                final digits = phone.number.replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                );
                                if (digits.length < _phoneMinLength ||
                                    digits.length > _phoneMaxLength) {
                                  return 'Enter a valid phone number for ${phone.countryISOCode}';
                                }

                                return ValidationService.validatePhoneNumber(
                                  phone.completeNumber,
                                );
                              },
                            ),

                            SizedBox(height: 12.h),

                            // ── Password ───────────────────────────────────
                            _FieldLabel(label: 'Password'),
                            SizedBox(height: 8.h),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              style: TextStyles.bodySmall.copyWith(
                                fontSize: 15.sp,
                                color: const Color(0xFF1A1A2E),
                              ),
                              decoration:
                                  _inputDecoration(
                                    hint: 'Create a strong password',
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 20.r,
                                        color: const Color(0xFF8A94A6),
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                              validator: (v) =>
                                  ValidationService.validatePassword(v),
                              onChanged: (_) => setState(() {}),
                            ),

                            // Password strength indicator
                            if (_passwordCtrl.text.isNotEmpty) ...[
                              SizedBox(height: 12.h),
                              _PasswordStrengthIndicator(
                                password: _passwordCtrl.text,
                              ),
                            ],

                            SizedBox(height: 14.h),

                            // API error (non field-specific)
                            if (_formError != null) ...[
                              ErrorBanner(message: _formError!),
                              SizedBox(height: 12.h),
                            ],

                            // ── Terms checkbox ─────────────────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 22.w,
                                  height: 22.h,
                                  child: Checkbox(
                                    value: _agreedToTerms,
                                    onChanged: (v) => setState(
                                      () => _agreedToTerms = v ?? false,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    side: BorderSide(
                                      color: AppTheme.primary,
                                      width: 1.5.w,
                                    ),
                                    activeColor: AppTheme.primary,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyles.captionRegular.copyWith(
                                        fontSize: 13.sp,
                                        color: AppTheme.textSecondary,
                                        height: 1.5,
                                      ),
                                      children: [
                                        const TextSpan(text: 'I agree to the '),
                                        TextSpan(
                                          text: 'Terms of Service',
                                          style: TextStyles.captionMedium
                                              .copyWith(
                                                color: AppTheme.primary,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13.sp,
                                              ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.pushNamed(
                                                context,
                                                AppRoutes.policyDetails,
                                                arguments: 'terms',
                                              );
                                            },
                                        ),
                                        const TextSpan(text: ' and '),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: TextStyles.captionMedium
                                              .copyWith(
                                                color: AppTheme.primary,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13.sp,
                                              ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.pushNamed(
                                                context,
                                                AppRoutes.policyDetails,
                                                arguments: 'privacy',
                                              );
                                            },
                                        ),
                                        const TextSpan(text: '.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 20.h),

                            // ── Register button ────────────────────────────
                            SizedBox(
                              width: double.infinity,
                              height: 54.h,
                              child: ElevatedButton.icon(
                                onPressed: isSubmitting ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor: AppColors.primary
                                      .withOpacity(0.5),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                ),
                                icon: isSubmitting
                                    ? SizedBox(
                                        width: 20.r,
                                        height: 20.r,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(Icons.person_add_alt_1, size: 20.r),
                                label: Text(
                                  isSubmitting ? 'Sending OTP...' : 'Register',
                                  style: TextStyles.bodyRegular.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 20.h),

                            // ── Login link ─────────────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account?',
                                  style: TextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    'Login',
                                    style: TextStyles.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shared input decoration factory
  InputDecoration _inputDecoration({required String hint, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyles.bodySmall.copyWith(color: const Color(0xFFB0BAC8)),
      errorText: errorText,
      errorStyle: TextStyles.captionRegular.copyWith(fontSize: 11.sp),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: const Color(0xFFE2E8F0), width: 1.5.w),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: const Color(0xFF2563EB), width: 1.5.w),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5.w),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5.w),
      ),
    );
  }
}

// ── Field label widget ─────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyles.bodySmall.copyWith(
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A2E),
      ),
    );
  }
}

// ── Password strength indicator ────────────────────────────────────────────────

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const _PasswordStrengthIndicator({required this.password});

  @override
  Widget build(BuildContext context) {
    final requirements = ValidationService.getPasswordRequirements(password);
    final metCount = requirements.values.where((v) => v).length;
    final totalCount = requirements.length;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password Strength',
                style: TextStyles.captionMedium.copyWith(
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              Text(
                '$metCount/$totalCount',
                style: TextStyles.captionMedium.copyWith(
                  color: metCount == totalCount
                      ? AppTheme.success
                      : AppTheme.error,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...requirements.entries.map(
            (e) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Icon(
                    e.value ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 15.r,
                    color: e.value ? AppTheme.success : const Color(0xFFB0BAC8),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    e.key,
                    style: TextStyles.captionRegular.copyWith(
                      fontSize: 12.sp,
                      color: e.value
                          ? AppTheme.success
                          : const Color(0xFF8A94A6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
