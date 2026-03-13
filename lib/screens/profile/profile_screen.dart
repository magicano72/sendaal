import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sendaal/services/api_client.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_account_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/app_widgets.dart';
import 'add_account_sheet.dart';
import 'edit_account_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          // Logout
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ── Profile Header ─────────────────────────────────────────────
            _ProfileHeader(user: user),
            const SizedBox(height: 8),

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
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Share Profile'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            const SizedBox(height: 28),

            // ── Accounts Section ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment Accounts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  onPressed: () => _showAddAccountSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
            else if (accountsState.accounts.isEmpty)
              const EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No accounts yet',
                subtitle: 'Add your first payment account to get started.',
              )
            else
              ...accountsState.accounts.map(
                (account) => AccountCard(
                  account: account,
                  showToggle: true,
                  showStar: true,
                  onToggleVisibility: (v) {
                    ref
                        .read(accountsProvider.notifier)
                        .toggleVisibility(account.id, account.isVisible);
                  },
                  onStar: () {
                    final newPriority = account.priority == 0 ? 1 : 0;
                    ref
                        .read(accountsProvider.notifier)
                        .updatePriority(account.id, newPriority);
                  },
                  onEdit: () => _openEditAccount(account),
                  onDelete: () => _confirmDeleteAccount(account),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddAccountSheet(),
    );
  }

  Future<void> _openEditAccount(FinancialAccount account) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditAccountScreen(account: account)),
    );

    final user = ref.read(authProvider).user;
    if (updated == true && user != null) {
      await ref.read(accountsProvider.notifier).loadAccounts(user.id);
    }
  }

  Future<void> _confirmDeleteAccount(FinancialAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          'This will remove ${account.accountIdentifier} from your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = ref.read(authProvider).user;
    try {
      await ref.read(accountsProvider.notifier).deleteAccount(account.id);

      if (user != null) {
        await ref.read(accountsProvider.notifier).loadAccounts(user.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
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
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceVariant,
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
                              style: const TextStyle(
                                fontSize: 32,
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
                          style: const TextStyle(
                            fontSize: 32,
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
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // First Name
        Text(
          user?.firstName ?? user?.displayName ?? 'User',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user != null ? '@${user!.username}' : '@username',
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),

        // Email
        if (user?.email != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 14,
                color: AppTheme.textHint,
              ),
              const SizedBox(width: 4),
              Text(
                user!.email!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],

        // Phone
        if (user?.phone != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 14,
                color: AppTheme.textHint,
              ),
              const SizedBox(width: 4),
              Text(
                user!.phone!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],

        if (user?.isVerified == true) ...[
          const SizedBox(height: 6),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, color: AppTheme.primary, size: 16),
              SizedBox(width: 4),
              Text(
                'Verified',
                style: TextStyle(
                  fontSize: 12,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPhotoFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Choose from Gallery'),
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
