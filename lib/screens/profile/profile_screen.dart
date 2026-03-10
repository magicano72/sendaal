import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import 'add_account_sheet.dart';

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
                    // Toggle priority between 0 (starred) and 1
                    // TODO: call update priority with account.priority == 0 ? 1 : 0
                  },
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
}

// ─── Profile Header widget ────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final dynamic user; // UserModel? (nullable)

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        CircleAvatar(
          radius: 44,
          backgroundColor: AppTheme.surfaceVariant,
          backgroundImage: user?.profileImage != null
              ? NetworkImage(user!.profileImage!)
              : null,
          child: user?.profileImage == null
              ? Text(
                  user?.displayName?.isNotEmpty == true
                      ? user!.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),

        Text(
          user?.displayName ?? 'Your Name',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user != null ? '@${user!.username}' : '@username',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),

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

        // QR placeholder
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child:
              const Icon(Icons.qr_code_2, size: 48, color: AppTheme.textHint),
        ),
        const SizedBox(height: 4),
        const Text(
          'QR Code (coming soon)',
          style: TextStyle(fontSize: 11, color: AppTheme.textHint),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
