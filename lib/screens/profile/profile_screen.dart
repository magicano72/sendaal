import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sendaal/services/api_client.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_account_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/app_widgets.dart';
import '../accounts/accounts_screen.dart';

/// My Profile Screen — shows the current user's profile and financial accounts
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load accounts after first frame so providers are ready
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
        leading: const SizedBox(), // Remove back button
        title: const Text('My Profile'),
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
            // ── Profile Header ─────────────────────────────────────────────
            _ProfileHeader(user: user),
            SizedBox(height: 8.h),

            // ── Share Profile ──────────────────────────────────────────────
            if (user != null)
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: 'sendaal.com/@${user.username}'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile link copied!')),
                  );
                },
                icon: Icon(Icons.share_outlined, size: 18.r),
                label: Text('Share Profile', style: TextStyle(fontSize: 14.sp)),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 44.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),

            SizedBox(height: 28.h),

            // ── Accounts Section ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Favorite Accounts',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.manage_accounts_outlined, size: 18.r),
                  label: Text('Manage', style: TextStyle(fontSize: 14.sp)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AccountsScreen()),
                    );
                  },
                ),
              ],
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
                title: 'No favorite accounts yet',
                subtitle: 'Manage accounts to star your favorites.',
              )
            else
              ...favoriteAccounts.map(
                (account) => AccountCard(
                  account: account,
                  dense: true,
                  showToggle: false,
                  showStar: true,
                  onStar: () => _toggleFavorite(account),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AccountsScreen()),
                    );
                  },
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
        icon: Icon(Icons.logout_outlined, color: AppTheme.error, size: 18.r),
        label: Text(
          'Log Out',
          style: TextStyle(
            color: AppTheme.error,
            fontWeight: FontWeight.w700,
            fontSize: 15.sp,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          backgroundColor: AppTheme.error.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(color: AppTheme.error.withOpacity(0.14)),
          ),
        ),
      ),
    );
  }
}
// ─── Profile Header widget ────────────────────────────────────────────────────

class _ProfileHeader extends ConsumerStatefulWidget {
  final dynamic user; // User? (nullable)

  const _ProfileHeader({required this.user});

  @override
  ConsumerState<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<_ProfileHeader> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Column(
      children: [
        // Avatar with upload button
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 88.w,
              height: 88.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.1),
              ),
              child: ClipOval(
                child: user?.avatar != null
                    ? Image.network(
                        _buildAvatarUrl(user!.avatar!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to initials if image fails to load
                          return Center(
                            child: Text(
                              user.firstName?.isNotEmpty == true
                                  ? user.firstName![0].toUpperCase()
                                  : (user.displayName.isNotEmpty == true
                                        ? user.displayName[0].toUpperCase()
                                        : '?'),
                              style: TextStyle(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          user?.firstName?.isNotEmpty == true
                              ? user!.firstName![0].toUpperCase()
                              : (user?.displayName.isNotEmpty == true
                                    ? user!.displayName[0].toUpperCase()
                                    : '?'),
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
              ),
            ),
            // Upload photo button
            GestureDetector(
              onTap: _isUploading ? null : () => _showPhotoOptions(context),
              child: Opacity(
                opacity: _isUploading ? 0.7 : 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(6.w),
                  child: _isUploading
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2.w,
                          ),
                        )
                      : Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 18.r,
                        ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // First Name
        Text(
          user?.firstName ?? user?.displayName ?? 'User',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          user != null ? '@${user!.username}' : '@username',
          style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondary),
        ),

        // Email
        if (user?.email != null) ...[
          SizedBox(height: 6.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.email_outlined,
                size: 14.r,
                color: AppTheme.textPrimary,
              ),
              SizedBox(width: 4.w),
              Text(
                user!.email!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],

        // Phone
        if (user?.phone != null) ...[
          SizedBox(height: 6.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_outlined, size: 14.r, color: AppTheme.primary),
              SizedBox(width: 4.w),
              Text(
                user!.phone!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],

        if (user?.isVerified == true) ...[
          SizedBox(height: 6.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, color: AppTheme.primary, size: 16.r),
              SizedBox(width: 4.w),
              Text(
                'Verified',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _buildAvatarUrl(String avatarId) {
    // Get base URL from ApiClient
    final baseUrl = ApiClient.instance.baseUrl;
    return '$baseUrl/assets/$avatarId';
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, size: 22.r),
              title: Text('Take Photo', style: TextStyle(fontSize: 15.sp)),
              onTap: () {
                Navigator.pop(context);
                _pickPhotoFromCamera();
              },
            ),
            ListTile(
              leading: Icon(Icons.image, size: 22.r),
              title: Text(
                'Choose from Gallery',
                style: TextStyle(fontSize: 15.sp),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickPhotoFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhotoFromCamera() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
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
    if (widget.user == null) return;

    setState(() => _isUploading = true);

    try {
      // Upload file to Directus storage
      final userService = UserService();
      final updatedUser = await userService.uploadAndUpdateAvatar(
        userId: widget.user!.id,
        filePath: filePath,
      );

      // Update auth provider with new user
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
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}
