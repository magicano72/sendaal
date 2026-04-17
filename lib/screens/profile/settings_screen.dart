import 'package:Sendaal/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../services/biometric_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BiometricService _biometricService = BiometricService();

  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _isUpdatingBiometric = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final available = await _biometricService.isDeviceSupported();
    final enabled = available && await _biometricService.isEnabled();

    if (!mounted) {
      return;
    }

    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (_isUpdatingBiometric) {
      return;
    }

    setState(() => _isUpdatingBiometric = true);

    bool updated = false;

    if (enable) {
      updated = await _biometricService.enableWithConfirmation();
    } else {
      await _biometricService.disable();
      updated = true;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdatingBiometric = false;
      if (updated) {
        _biometricEnabled = enable;
      }
    });

    if (updated) {
      AppSnackBar.success(
        context,
        enable ? 'Biometric login enabled' : 'Biometric login disabled',
      );
      return;
    }

    if (enable) {
      AppSnackBar.error(
        context,
        'Biometric verification failed. Biometric login was not enabled.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              children: [
                _SettingsSectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppTheme.primary,
                      ),
                    ),
                    title: Text(
                      'Profile Detail',
                      style: TextStyles.bodyBold.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'View all of your account details.',
                      style: TextStyles.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.profileDetails);
                    },
                  ),
                ),
                SizedBox(height: 16.h),
                if (_biometricAvailable)
                  _SettingsSectionCard(
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _biometricEnabled,
                      onChanged: _isUpdatingBiometric ? null : _toggleBiometric,
                      activeColor: AppTheme.primary,
                      secondary: _isUpdatingBiometric
                          ? SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Container(
                              width: 42.w,
                              height: 42.w,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: const Icon(
                                Icons.fingerprint_rounded,
                                color: AppTheme.primary,
                              ),
                            ),
                      title: Text(
                        'Use biometric login',
                        style: TextStyles.bodyBold.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Use your device biometrics from the PIN screen.',
                        style: TextStyles.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  _SettingsSectionCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 42.w,
                        height: 42.w,
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      title: Text(
                        'Biometric login',
                        style: TextStyles.bodyBold.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'This device does not support biometrics.',
                        style: TextStyles.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 24.h),
                // Privacy & Policy Section
                Text(
                  'Privacy & Legal',
                  style: TextStyles.bodyBold.copyWith(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                // Privacy Policy
                _SettingsSectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                    title: Text(
                      'Privacy Policy',
                      style: TextStyles.bodyBold.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'View our privacy practices.',
                      style: TextStyles.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.policyDetails,
                        arguments: 'privacy',
                      );
                    },
                  ),
                ),
                SizedBox(height: 12.h),
                // Terms & Conditions
                _SettingsSectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                    title: Text(
                      'Terms & Conditions',
                      style: TextStyles.bodyBold.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Read our terms of service.',
                      style: TextStyles.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.policyDetails,
                        arguments: 'terms',
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  final Widget child;

  const _SettingsSectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}
