import 'dart:io';

import 'package:Sendaal/widgets/account_card.dart';
import 'package:Sendaal/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../models/financial_account_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/app_widgets.dart';

/// My Profile screen styled to match the provided fintech design.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(accountsProvider.notifier).loadAccounts(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final accountsState = ref.watch(accountsProvider);
    final user = auth.user;
    final allVisibleAccounts =
        accountsState.accounts.where((a) => a.isVisible).toList();
    final favoriteAccounts =
        allVisibleAccounts.where((a) => a.isFavourite).toList();

    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox(),
        title: const Text('My Profile'),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            await ref.read(accountsProvider.notifier).loadAccounts(user.id);
          }
        },
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          children: [
            _ProfileHeader(
              user: user,
              onPickAvatar: _pickPhotoFromGallery,
              isUploading: _isUploading,
            ),
            SizedBox(height: 20.h),
            if (user != null) _ShareLinkButton(username: user.username),
            SizedBox(height: 28.h),
            Text(
              'Favorite Accounts',
              style: TextStyles.bodyBold.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            if (accountsState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (accountsState.error != null)
              ErrorBanner(
                message: accountsState.error!,
                onRetry: () {
                  if (user != null) {
                    ref.read(accountsProvider.notifier).loadAccounts(user.id);
                  }
                },
              )
            else if (favoriteAccounts.isEmpty && allVisibleAccounts.isEmpty)
              const EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No accounts yet',
                subtitle: 'Add accounts to see them here.',
              )
            else if (favoriteAccounts.isEmpty)
              const EmptyState(
                icon: Icons.favorite_border,
                title: 'No favorite accounts',
                subtitle: 'Tap the heart on an account to pin it here.',
              )
            else ...[
              ...favoriteAccounts.map(
                (account) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: AccountCard(
                    account: account,
                    dense: false,
                    showToggle: false,
                    showStar: true,
                    onStar: () => _toggleFavorite(account),
                    onTap: () {},
                  ),
                ),
              ),
            ],
            SizedBox(height: 28.h),
            _LogoutButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                }
              },
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(FinancialAccount account) async {
    final notifier = ref.read(accountsProvider.notifier);
    await notifier.toggleFavourite(account.id, account.isFavourite);

    final user = ref.read(authProvider).user;
    if (user != null) {
      await notifier.loadAccounts(user.id);
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    // Don't allow picking while already uploading
    if (_isUploading) return;

    final allowed = await _ensurePhotoPermission();
    if (!allowed) return;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Start loading immediately after the user picks a photo
        if (mounted) setState(() => _isUploading = true);
        await _uploadPhoto(image.path);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to pick photo.');
      }
    }
  }

  Future<bool> _ensurePhotoPermission() async {
    if (!Platform.isIOS && !Platform.isAndroid) return true;

    var status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      final goSettings = await _showPhotoSettingsDialog();
      if (goSettings) await openAppSettings();
      return false;
    }

    final proceed = await _showPhotoRationaleDialog();
    if (!proceed) return false;

    status = await Permission.photos.request();
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      final goSettings = await _showPhotoSettingsDialog();
      if (goSettings) await openAppSettings();
    }
    return false;
  }

  Future<bool> _showPhotoRationaleDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allow photo access'),
        content: const Text(
          'Sendaal needs access to your photos so you can choose a profile picture.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _showPhotoSettingsDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable photos in Settings'),
        content: const Text(
          'Photo access is disabled. Open Settings to enable photos for Sendaal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _uploadPhoto(String filePath) async {
    final current = ref.read(authProvider).user;
    if (current == null) {
      if (mounted) setState(() => _isUploading = false);
      return;
    }

    // _isUploading is already true when called from _pickPhotoFromGallery
    try {
      final userService = UserService();
      final updatedUser = await userService.uploadAndUpdateAvatar(
        userId: current.id,
        filePath: filePath,
      );
      ref.read(authProvider.notifier).setUser(updatedUser);
      if (mounted) {
        AppSnackBar.success(context, 'Profile photo updated successfully');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to upload photo.');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

class _ShareLinkButton extends StatelessWidget {
  final String username;
  const _ShareLinkButton({required this.username});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: 'sendaal.com/@$username'));
        AppSnackBar.success(context, 'Profile link copied to clipboard!');
      },
      icon: const Icon(Icons.share, color: AppTheme.primary),
      label: Text(
        'Share Account Link',
        style: TextStyles.bodyBold.copyWith(color: AppTheme.textPrimary),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        backgroundColor: const Color(0xFFEFF2F6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LogoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_outlined, color: AppTheme.error),
        label: Text(
          'Log Out',
          style: TextStyles.bodySmallBold.copyWith(
            color: AppTheme.error,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          backgroundColor: AppTheme.error.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
            side: BorderSide(color: AppTheme.error.withOpacity(0.14)),
          ),
        ),
      ),
    );
  }
}

// Profile header with avatar, edit badge, name and username.
class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  final VoidCallback onPickAvatar;
  final bool isUploading;

  const _ProfileHeader({
    required this.user,
    required this.onPickAvatar,
    required this.isUploading,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar =
        user?.avatarUrl != null && (user.avatarUrl as String).isNotEmpty;
    final initials = user == null
        ? '?'
        : (user.firstName?.isNotEmpty ?? false)
        ? user.firstName![0].toUpperCase()
        : (user.displayName.isNotEmpty
              ? user.displayName[0].toUpperCase()
              : user.username[0].toUpperCase());

    return Column(
      children: [
        Stack(
          children: [
            // ── Avatar circle ─────────────────────────────────────────────
            Container(
              width: 110.w,
              height: 110.w,
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.1),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The actual avatar image / initials
                  Positioned.fill(
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: hasAvatar
                          ? NetworkImage(user.avatarUrl)
                          : null,
                      child: hasAvatar
                          ? null
                          : Text(
                              initials,
                              style: TextStyles.h1Semi.copyWith(
                                fontSize: 30.sp,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                    ),
                  ),

                  // ── Loading overlay on top of avatar ───────────────────
                  if (isUploading)
                    Positioned.fill(
                      child: ClipOval(
                        child: Container(
                          color: Colors.black.withOpacity(0.45),
                          child: Center(
                            child: SizedBox(
                              width: 28.w,
                              height: 28.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Edit / uploading badge ────────────────────────────────────
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: isUploading ? null : onPickAvatar,
                child: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: isUploading
                        ? AppTheme.primary.withOpacity(0.6)
                        : AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isUploading
                      ? Padding(
                          padding: EdgeInsets.all(6.w),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          user?.firstName?.isNotEmpty == true
              ? user.firstName!
              : (user?.displayName ?? 'User'),
          style: TextStyles.h1Semi.copyWith(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          user != null ? '@${user.username}' : '@username',
          style: TextStyles.label.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
