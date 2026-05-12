import 'package:Sendaal/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/text_style.dart';
import '../../services/biometric_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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

  Future<void> _showThemeModeSheet(AppThemeMode selectedMode) async {
    final pickedMode = await showModalBottomSheet<AppThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme Mode',
                style: TextStyles.h2Medium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Choose how Sendaal looks on this device.',
                style: TextStyles.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 18.h),
              for (final mode in AppThemeMode.values) ...[
                _ThemeModeOption(
                  mode: mode,
                  selected: mode == selectedMode,
                  onTap: () => Navigator.pop(context, mode),
                ),
                if (mode != AppThemeMode.values.last) SizedBox(height: 10.h),
              ],
            ],
          ),
        );
      },
    );

    if (pickedMode == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    await ref.read(themeModeProvider.notifier).setThemeMode(pickedMode);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
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
                      child: Icon(
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
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.profileDetails);
                    },
                  ),
                ),
                SizedBox(height: 16.h),
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
                      child: Icon(themeMode.icon, color: AppTheme.primary),
                    ),
                    title: Text(
                      'Appearance',
                      style: TextStyles.bodyBold.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        themeMode.subtitle,
                        key: ValueKey(themeMode),
                        style: TextStyles.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    onTap: () => _showThemeModeSheet(themeMode),
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
                              child: Icon(
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
                        child: Icon(
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
                      child: Icon(
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
                    trailing: Icon(
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
                      child: Icon(
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
                    trailing: Icon(
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

class _ThemeModeOption extends StatelessWidget {
  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeModeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary.withOpacity(0.14) : AppTheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: selected ? AppTheme.primary : AppTheme.border,
          width: selected ? 1.4.w : 1.w,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(selected ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(mode.icon, color: AppTheme.primary),
        ),
        title: Text(
          mode.title,
          style: TextStyles.bodyBold.copyWith(color: AppTheme.textPrimary),
        ),
        trailing: AnimatedScale(
          scale: selected ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: Icon(Icons.check_circle_rounded, color: AppTheme.primary),
        ),
        onTap: onTap,
      ),
    );
  }
}
