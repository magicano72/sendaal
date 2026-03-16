import 'package:Sendaal/widgets/app_snackbar.dart';
import 'package:Sendaal/widgets/app_widgets.dart' show ErrorBanner;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/error/exceptions.dart';
import '../../core/router/app_router.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/directus_error_parser.dart';
import '../../core/services/validation_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _firstNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _agreedToTerms = false;
  final _formKey = GlobalKey<FormState>();
  String? _formError; // non-field specific API errors

  // Field-level error tracking for API errors
  String? _usernameError;
  String? _emailError;
  String? _phoneError;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your network.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .register(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          username: _usernameCtrl.text.trim(),
          firstName: _firstNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );

    if (!mounted) return;

    // Check for field-level errors in the auth error
    final authError = ref.read(authProvider).error;
    if (authError != null && !success) {
      try {
        final apiEx = ApiException(message: authError);

        _usernameError = DirectusErrorParser.parseFieldError(apiEx, 'username');
        _emailError = DirectusErrorParser.parseFieldError(apiEx, 'email');
        _phoneError = DirectusErrorParser.parseFieldError(apiEx, 'phone');

        final hasFieldError =
            _usernameError != null ||
            _emailError != null ||
            _phoneError != null;

        if (hasFieldError) {
          setState(() {});
          _formKey.currentState?.validate();
        } else {
          setState(
            () =>
                _formError = DirectusErrorParser.getGeneralErrorMessage(apiEx),
          );
        }
      } catch (e) {
        debugPrint('Error parsing field error: $e');
        setState(() => _formError = 'Something went wrong. $authError');
      }
    }

    if (success) {
      AppSnackBar.success(
        context,
        'Account created successfully! Please log in.',
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

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
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: TextStyles.bodySmall.copyWith(
                                fontSize: 15.sp,
                                color: const Color(0xFF1A1A2E),
                              ),
                              decoration: _inputDecoration(
                                hint: '01x-xxx-xxxx',
                                errorText: _phoneError,
                              ),
                              validator: (v) =>
                                  ValidationService.validatePhone(v),
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

                            // ── Terms checkbox ─────────────────────────────
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
                                  child: Text.rich(
                                    TextSpan(
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
                                onPressed: auth.isRegisterLoading
                                    ? null
                                    : _register,
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
                                icon: auth.isRegisterLoading
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
                                  auth.isRegisterLoading
                                      ? 'Creating...'
                                      : 'Register',
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
      hintStyle: TextStyle(fontSize: 14.sp, color: const Color(0xFFB0BAC8)),
      errorText: errorText,
      errorStyle: TextStyle(fontSize: 11.sp),
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
                    style: TextStyle(
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
