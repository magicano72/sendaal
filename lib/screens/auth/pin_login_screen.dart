import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_session_service.dart';
import '../../services/biometric_service.dart';
import '../../services/session_manager.dart';
import 'splash_screen.dart';
import '../../widgets/pin_entry_widgets.dart';
import '../../widgets/shimmer_widgets.dart';

class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  final AuthSessionService _sessionService = AuthSessionService.instance;
  final BiometricService _biometricService = BiometricService();

  String _enteredPin = '';
  String _displayName = 'there';
  String? _error;
  int _attemptsRemaining = AuthSessionService.kMaxAttempts;
  int? _lockRemainingSeconds;
  bool _isLoading = true;
  bool _isVerifying = false;
  bool _isLoggingOut = false;
  bool _showBiometricButton = false;
  bool _shouldAutoTriggerBiometric = false;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    final splashResult = ref.read(splashInitializationProvider);
    if (splashResult?.nextRoute == AppRoutes.pinLogin) {
      _displayName = splashResult?.displayName ?? 'there';
      _showBiometricButton = splashResult?.showBiometricButton ?? false;
      _shouldAutoTriggerBiometric = _showBiometricButton;
      _isLoading = false;
      _restoreLockState();
    } else {
      _bootstrap();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Trigger biometric after UI has settled
    if (_shouldAutoTriggerBiometric && !_isLoading && !_isVerifying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _shouldAutoTriggerBiometric = false;
          _authenticateWithBiometric();
        }
      });
    }
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final route = await _sessionService.getInitialRoute();
    if (!mounted) {
      return;
    }

    if (route == AppRoutes.login) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      return;
    }

    if (route == AppRoutes.pinSetup) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.pinSetup,
        (_) => false,
      );
      return;
    }

    final authUser = ref.read(authProvider).user;
    final storedName = await _sessionService.readStoredDisplayName();
    final showBiometricButton =
        await _sessionService.isBiometricEnabled() &&
        await _sessionService.canUseBiometric();

    await _restoreLockState();

    if (!mounted) {
      return;
    }

    setState(() {
      _displayName = _sessionService.displayNameForUser(
        authUser,
        fallback: storedName ?? 'there',
      );
      _showBiometricButton = showBiometricButton;
      _shouldAutoTriggerBiometric = showBiometricButton;
      _isLoading = false;
    });
  }

  Future<void> _restoreLockState() async {
    final lockUntilStr = await _sessionService.secureStorage.read(
      key: kPinLockUntil,
    );
    if (lockUntilStr == null) {
      return;
    }

    final lockUntil = DateTime.tryParse(lockUntilStr);
    if (lockUntil == null) {
      await _sessionService.secureStorage.delete(key: kPinLockUntil);
      return;
    }

    final remaining = lockUntil.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      await _sessionService.clearPinLockState();
      return;
    }

    _startLockCountdown(remaining);
  }

  void _startLockCountdown(int seconds) {
    _lockTimer?.cancel();
    setState(() {
      _lockRemainingSeconds = seconds;
      _error = 'Too many attempts. Try again in $seconds seconds.';
    });

    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final next = (_lockRemainingSeconds ?? 1) - 1;
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (next <= 0) {
        timer.cancel();
        await _sessionService.clearPinLockState();
        if (!mounted) {
          return;
        }
        setState(() {
          _lockRemainingSeconds = null;
          _error = null;
          _attemptsRemaining = AuthSessionService.kMaxAttempts;
        });
        return;
      }

      setState(() {
        _lockRemainingSeconds = next;
        _error = 'Too many attempts. Try again in $next seconds.';
      });
    });
  }

  Future<void> _handleDigit(String value) async {
    if (_isVerifying || _isLoggingOut || _lockRemainingSeconds != null) {
      return;
    }

    if (_enteredPin.length >= 4) {
      return;
    }

    setState(() {
      _enteredPin += value;
      if (_error != null &&
          _attemptsRemaining == AuthSessionService.kMaxAttempts) {
        _error = null;
      }
    });

    if (_enteredPin.length == 4) {
      await _verifyPin();
    }
  }

  void _handleDelete() {
    if (_isVerifying ||
        _isLoggingOut ||
        _enteredPin.isEmpty ||
        _lockRemainingSeconds != null) {
      return;
    }

    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      if (_attemptsRemaining == AuthSessionService.kMaxAttempts) {
        _error = null;
      }
    });
  }

  Future<void> _verifyPin() async {
    setState(() => _isVerifying = true);
    final result = await _sessionService.verifyPin(_enteredPin);

    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      setState(() {
        _enteredPin = '';
        _isVerifying = false;
        _error = result.message;
        _attemptsRemaining = result.attemptsRemaining;
      });

      if (result.lockRemainingSeconds != null &&
          result.lockRemainingSeconds! > 0) {
        _startLockCountdown(result.lockRemainingSeconds!);
      }
      return;
    }

    // Reset session lock state on successful PIN verification
    SessionManager.instance.resetLockState();

    final readyForHome = await ref
        .read(authProvider.notifier)
        .bootstrapAuthenticatedUser();

    if (!mounted) {
      return;
    }

    setState(() {
      _enteredPin = '';
      _isVerifying = false;
    });
    if (!readyForHome) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      return;
    }

    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isVerifying || _isLoggingOut) {
      return;
    }

    setState(() => _isVerifying = true);

    // Use BiometricService for better error handling and status detection
    final result = await _biometricService.authenticate(
      reason: 'Log in to Sendaal',
    );

    if (!mounted) {
      return;
    }

    // If successful, proceed to bootstrap and navigate
    if (result.success) {
      // Reset session lock state on successful biometric authentication
      SessionManager.instance.resetLockState();

      final readyForHome = await ref
          .read(authProvider.notifier)
          .bootstrapAuthenticatedUser();

      if (!mounted) {
        return;
      }

      setState(() => _isVerifying = false);

      if (!readyForHome) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        );
        return;
      }

      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
      return;
    }

    // If user canceled, just hide the loading state - let them use PIN
    if (result.status == BiometricStatus.userCanceled) {
      setState(() => _isVerifying = false);
      return;
    }

    // For other errors (device locked, etc), clear and let user retry or use PIN
    setState(() => _isVerifying = false);
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Forgot PIN will log you out of this device and return you to the login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    setState(() => _isLoggingOut = true);
    await ref.read(authProvider.notifier).logout();
    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: PinScreenScaffold(
        child: _isLoggingOut
            ? const _PinLogoutShimmer()
            : _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PinSectionTitle(
                    title: 'Welcome back, $_displayName',
                    subtitle: 'Enter your PIN to continue into Sendaal',
                  ),
                  SizedBox(height: 30.h),
                  PinDots(length: 4, filled: _enteredPin.length),
                  SizedBox(height: 18.h),
                  if (_error != null)
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      'Enter your 4-digit PIN',
                      style: TextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (_attemptsRemaining < AuthSessionService.kMaxAttempts &&
                      _lockRemainingSeconds == null) ...[
                    SizedBox(height: 10.h),
                    Text(
                      '$_attemptsRemaining attempts remaining',
                      style: TextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  SizedBox(height: 34.h),
                  if (_isVerifying)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 28.h),
                      child: const CircularProgressIndicator(),
                    )
                  else
                    PinKeypad(
                      showBiometricButton: _showBiometricButton,
                      onBiometricPressed: _authenticateWithBiometric,
                      onNumberPressed: _handleDigit,
                      onDeletePressed: _handleDelete,
                    ),
                  if (_showBiometricButton) ...[
                    SizedBox(height: 20.h),
                    TextButton.icon(
                      onPressed: _authenticateWithBiometric,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Use biometric'),
                    ),
                  ],
                  SizedBox(height: 14.h),
                  TextButton(
                    onPressed: _confirmLogout,
                    child: Text(
                      'Forgot PIN / Log out',
                      style: TextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PinLogoutShimmer extends StatelessWidget {
  const _PinLogoutShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 220.w,
          child: ShimmerCard(
            height: 28,
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        SizedBox(height: 14.h),
        SizedBox(
          width: 260.w,
          child: ShimmerCard(
            height: 16,
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        SizedBox(height: 30.h),
        SizedBox(
          width: 120.w,
          child: ShimmerCard(
            height: 18,
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
        SizedBox(height: 14.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (_) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: SizedBox(
                width: 18.r,
                child: ShimmerCard(
                  height: 18,
                  margin: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 18.h),
        SizedBox(
          width: 180.w,
          child: ShimmerCard(
            height: 16,
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        SizedBox(height: 34.h),
        ...List.generate(
          3,
          (_) => Padding(
            padding: EdgeInsets.only(bottom: 18.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Padding(
                  padding: EdgeInsets.only(
                    right: index == 2 ? 0 : 18.w,
                  ),
                  child: SizedBox(
                    width: 84.w,
                    child: ShimmerCard(
                      height: 72,
                      margin: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(
                right: index == 2 ? 0 : 18.w,
              ),
              child: SizedBox(
                width: 84.w,
                child: ShimmerCard(
                  height: 72,
                  margin: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(22.r),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          width: 160.w,
          child: ShimmerCard(
            height: 18,
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ],
    );
  }
}
