import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/validation_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

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
  final _formKey = GlobalKey<FormState>();

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
    });

    if (!_formKey.currentState!.validate()) return;

    // Check internet connection before API call
    final connectivity = ConnectivityService();
    final hasInternet = await connectivity.hasInternetConnection();

    if (!hasInternet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your network.'),
            backgroundColor: Colors.red,
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
      // Try to parse as API error
      try {
        if (authError.contains('username') && authError.contains('unique')) {
          setState(() {
            _usernameError =
                'This username is already taken. Please choose another.';
          });
          _formKey.currentState?.validate();
        } else if (authError.contains('email') &&
            authError.contains('unique')) {
          setState(() {
            _emailError =
                'This email is already registered. Try logging in instead.';
          });
          _formKey.currentState?.validate();
        } else if (authError.contains('phone') &&
            authError.contains('unique')) {
          setState(() {
            _phoneError = 'This phone number is already registered.';
          });
          _formKey.currentState?.validate();
        }
      } catch (e) {
        print('Error parsing field error: $e');
      }
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please sign in.'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join Sendaal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create your account to start splitting payments.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),

                // First Name
                TextFormField(
                  controller: _firstNameCtrl,
                  keyboardType: TextInputType.name,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'e.g. John',
                  ),
                  validator: (v) =>
                      ValidationService.validateName(v, minLength: 2),
                ),
                const SizedBox(height: 16),

                // Username
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.alternate_email),
                    hintText: 'e.g. john_doe',
                    errorText: _usernameError,
                  ),
                  validator: (v) => ValidationService.validateUsername(v),
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    errorText: _emailError,
                  ),
                  validator: (v) => ValidationService.validateEmail(v),
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    hintText: 'e.g. 01234567890',
                    errorText: _phoneError,
                  ),
                  validator: (v) => ValidationService.validatePhone(v),
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    hintText:
                        'Min 8 chars, uppercase, lowercase, number, special',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => ValidationService.validatePassword(v),
                  onChanged: (_) => setState(() {}),
                ),

                // Password strength indicator
                if (_passwordCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _PasswordStrengthIndicator(password: _passwordCtrl.text),
                ],

                const SizedBox(height: 28),

                PrimaryButton(
                  label: 'Create Account',
                  isLoading: auth.isLoading,
                  onPressed: _register,
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Password strength indicator widget
class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  @override
  Widget build(BuildContext context) {
    final requirements = ValidationService.getPasswordRequirements(password);
    final metCount = requirements.values.where((v) => v).length;
    final totalCount = requirements.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Password Strength',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '$metCount/$totalCount',
                style: TextStyle(
                  fontSize: 12,
                  color: metCount == totalCount
                      ? AppTheme.success
                      : AppTheme.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...requirements.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    e.value ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: e.value ? AppTheme.success : AppTheme.textHint,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    e.key,
                    style: TextStyle(
                      fontSize: 12,
                      color: e.value
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
