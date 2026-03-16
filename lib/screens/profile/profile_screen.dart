import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_account_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/app_widgets.dart';
import '../accounts/accounts_screen.dart';

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
    final favoriteAccounts = accountsState.accounts
        .where((a) => a.isVisible && a.priority == 0)
        .toList();

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
              style: TextStyle(
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
            else if (favoriteAccounts.isEmpty)
              const EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No accounts yet',
                subtitle: 'Add accounts to see them here.',
              )
            else
              ...favoriteAccounts.map(
                (account) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: AccountCard(
                    account: account,
                    dense: false,
                    showToggle: false,
                    showStar: true,
                    onStar: () => _toggleFavorite(account),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AccountsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
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
    final newPriority = account.priority == 0 ? 1 : 0;
    await notifier.updatePriority(account.id, newPriority);

    final user = ref.read(authProvider).user;
    if (user != null) {
      await notifier.loadAccounts(user.id);
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await _uploadPhoto(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _uploadPhoto(String filePath) async {
    final current = ref.read(authProvider).user;
    if (current == null) return;

    setState(() => _isUploading = true);

    try {
      final userService = UserService();
      final updatedUser = await userService.uploadAndUpdateAvatar(
        userId: current.id,
        filePath: filePath,
      );
      ref.read(authProvider.notifier).setUser(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading photo: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile link copied!')));
      },
      icon: const Icon(Icons.share, color: AppTheme.primary),
      label: const Text(
        'Share Account Link',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w700,
        ),
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
        label: const Text(
          'Log Out',
          style: TextStyle(
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
            Container(
              width: 110.w,
              height: 110.w,
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.1),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: hasAvatar
                    ? NetworkImage(user.avatarUrl)
                    : null,
                child: hasAvatar
                    ? null
                    : Text(
                        initials,
                        style: TextStyle(
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: isUploading ? null : onPickAvatar,
                child: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
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
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          user != null ? '@${user.username}' : '@username',
          style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
