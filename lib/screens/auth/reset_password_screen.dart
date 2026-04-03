import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../repositories/password_reset_repository.dart';
import '../../services/api_client.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _repository = PasswordResetRepository();

  bool _isSubmitting = false;
  bool _showErrors = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _linkError;

  bool get _hasToken =>
      widget.token != null && widget.token!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_hasToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppSnackBar.error(
          context,
          'Invalid reset link. Please request a new one.',
        );
        _goToForgotPassword(replace: true);
      });
    }
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Add at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Add at least one number';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordCtrl.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  bool get _isFormValid =>
      _hasToken &&
      _validatePassword(_passwordCtrl.text) == null &&
      _validateConfirm(_confirmCtrl.text) == null;

  Future<void> _submit() async {
    setState(() {
      _showErrors = true;
      _linkError = null;
    });
    if (!_isFormValid) {
      _formKey.currentState?.validate();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _repository.resetPassword(
        token: widget.token!.trim(),
        newPassword: _passwordCtrl.text,
      );
      if (!mounted) return;
      AppSnackBar.success(
        context,
        'Password reset successfully. Please log in.',
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401 || e.statusCode == 404) {
        setState(() {
          _linkError =
              'This reset link is invalid or has expired. Please request a new one.';
        });
      } else {
        AppSnackBar.error(
          context,
          'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goToForgotPassword({bool replace = false}) {
    if (replace) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.forgotPassword,
        (route) => false,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.forgotPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(
            context,
            AppRoutes.login,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
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
            child: Form(
              key: _formKey,
              autovalidateMode: _showErrors
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create a new password',
                    style: TextStyles.h1Semi.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 24.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Your new password must be at least 8 characters long and include an uppercase letter and a number.',
                    style: TextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (_linkError != null) ...[
                    SizedBox(height: 16.h),
                    ErrorBanner(message: _linkError!),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _goToForgotPassword(replace: true),
                        child: const Text('Request a new link'),
                      ),
                    ),
                  ],
                  SizedBox(height: 18.h),
                  Text(
                    'New password',
                    style: TextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'Enter new password',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: _validatePassword,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Confirm password',
                    style: TextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'Re-enter new password',
                      prefixIcon: const Icon(
                        Icons.lock_reset_outlined,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                      ),
                    ),
                    validator: _validateConfirm,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 24.h),
                  PrimaryButton(
                    label: 'Update password',
                    onPressed:
                        _isSubmitting || !_isFormValid ? null : _submit,
                    isLoading: _isSubmitting,
                  ),
                  SizedBox(height: 12.h),
                  Center(
                    child: TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.login,
                              ),
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
