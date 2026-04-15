import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_session_service.dart';
import '../../services/biometric_service.dart';
import '../../widgets/biometric_enrollment_sheet.dart';
import '../../widgets/pin_entry_widgets.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  final AuthSessionService _sessionService = AuthSessionService.instance;
  final BiometricService _biometricService = BiometricService();

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  String _firstPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isSubmitting = false;
  bool _isCheckingRoute = true;
  bool _isBiometricEnrolling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(_shakeController);
    _guardRoute();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _guardRoute() async {
    final route = await _sessionService.getInitialRoute();
    if (!mounted) {
      return;
    }

    if (route == AppRoutes.login) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      return;
    }

    if (route == AppRoutes.pinLogin) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.pinLogin,
        (_) => false,
      );
      return;
    }

    setState(() => _isCheckingRoute = false);
  }

  Future<void> _handleDigit(String value) async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _error = null;
      if (_isConfirming) {
        if (_confirmPin.length < 4) {
          _confirmPin += value;
        }
      } else if (_firstPin.length < 4) {
        _firstPin += value;
      }
    });

    if (!_isConfirming && _firstPin.length == 4) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) {
        return;
      }
      setState(() => _isConfirming = true);
      return;
    }

    if (_isConfirming && _confirmPin.length == 4) {
      await _submitPin();
    }
  }

  void _handleDelete() {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _error = null;
      if (_isConfirming && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (!_isConfirming && _firstPin.isNotEmpty) {
        _firstPin = _firstPin.substring(0, _firstPin.length - 1);
      }
    });
  }

  Future<void> _submitPin() async {
    if (_firstPin != _confirmPin) {
      await _shakeController.forward(from: 0);
      if (!mounted) {
        return;
      }
      setState(() {
        _firstPin = '';
        _confirmPin = '';
        _isConfirming = false;
        _error = "PINs don't match, try again";
      });
      return;
    }

    setState(() => _isSubmitting = true);

    await _sessionService.savePin(_firstPin);

    var readyForHome = ref.read(authProvider).user != null;
    if (!readyForHome) {
      readyForHome = await ref
          .read(authProvider.notifier)
          .bootstrapAuthenticatedUser();
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (!readyForHome) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      return;
    }

    // Show biometric enrollment prompt after successful PIN setup
    _showBiometricEnrollmentPrompt();
  }

  Future<void> _showBiometricEnrollmentPrompt() async {
    // Check if biometric is supported on this device
    final isSupported = await _biometricService.isDeviceSupported();
    if (!isSupported || !mounted) {
      // Skip biometric and go to home
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
      return;
    }

    // Show bottom sheet, don't auto-dismiss on action
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => BiometricEnrollmentBottomSheet(
        isLoading: _isBiometricEnrolling,
        onEnable: _handleBiometricEnable,
        onSkip: _handleBiometricSkip,
      ),
    );
  }

  Future<void> _handleBiometricEnable() async {
    setState(() => _isBiometricEnrolling = true);

    // Attempt to enable biometric with confirmation
    final success = await _biometricService.enableWithConfirmation();

    if (!mounted) return;

    setState(() => _isBiometricEnrolling = false);

    if (success) {
      // Pop the bottom sheet and navigate to home
      Navigator.of(context).pop();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } else {
      // User canceled biometric - just pop sheet
      // They can try again later from Profile
      Navigator.of(context).pop();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    }
  }

  Future<void> _handleBiometricSkip() async {
    // Mark that user skipped enrollment in this session
    await _biometricService.markSkipped();

    if (!mounted) return;

    // Pop the bottom sheet and navigate to home
    Navigator.of(context).pop();
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final enteredLength = _isConfirming ? _confirmPin.length : _firstPin.length;

    return WillPopScope(
      onWillPop: () async => false,
      child: PinScreenScaffold(
        child: _isCheckingRoute
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PinSectionTitle(
                    title: _isConfirming
                        ? 'Confirm your PIN'
                        : 'Create your PIN',
                    subtitle: _isConfirming
                        ? 'Enter it again to make sure it is correct'
                        : "You'll use this every time you open Sendaal",
                  ),
                  SizedBox(height: 30.h),
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: PinDots(length: 4, filled: enteredLength),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    _isConfirming
                        ? 'Re-enter your 4-digit PIN'
                        : 'Enter a 4-digit PIN',
                    style: TextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_error != null) ...[
                    SizedBox(height: 14.h),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  SizedBox(height: 34.h),
                  if (_isSubmitting)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 28.h),
                      child: const CircularProgressIndicator(),
                    )
                  else
                    PinKeypad(
                      onNumberPressed: _handleDigit,
                      onDeletePressed: _handleDelete,
                    ),
                ],
              ),
      ),
    );
  }
}
