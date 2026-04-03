import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/router/app_router.dart';
import '../../core/services/validation_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../repositories/password_reset_repository.dart';
import '../../services/api_client.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _repository = PasswordResetRepository();

  bool _isSubmitting = false;
  bool _emailTouched = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    _emailTouched = true;
    return ValidationService.validateEmail(value);
  }

  bool get _isEmailValid =>
      ValidationService.validateEmail(_emailCtrl.text.trim()) == null;

  Future<void> _submit() async {
    setState(() => _emailTouched = true);
    if (!_isEmailValid) {
      _formKey.currentState?.validate();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _repository.requestPasswordReset(_emailCtrl.text.trim());
      if (!mounted) return;
      AppSnackBar.info(
        context,

        'If this email is registered, you will receive a reset link shortly.',
      );
    } on ApiException {
      if (!mounted) return;
      AppSnackBar.error(context, 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goBackToLogin() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToLogin,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Form(
            key: _formKey,
            autovalidateMode: _emailTouched
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 18.r,
                    offset: Offset(0, 10.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reset your password',
                    style: TextStyles.h1Semi.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 24.sp,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Enter the email associated with your account and we\'ll send you a link to reset your password.',
                    style: TextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Text(
                    'Email Address',
                    style: TextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'name@example.com',
                      prefixIcon: Icon(
                        Icons.mail_outline,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    validator: _emailValidator,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 26.h),
                  PrimaryButton(
                    label: 'Send reset link',
                    onPressed: _isSubmitting || !_isEmailValid ? null : _submit,
                    isLoading: _isSubmitting,
                  ),
                  SizedBox(height: 14.h),
                  Center(
                    child: TextButton(
                      onPressed: _goBackToLogin,
                      child: const Text('Back to login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
