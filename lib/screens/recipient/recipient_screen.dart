import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sendaal/models/access_request_model.dart';
import 'package:sendaal/providers/access_request_provider.dart';
import 'package:sendaal/providers/auth_provider.dart';

import '../../core/models/user_model.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_account_model.dart';
import '../../providers/account_provider.dart';
import '../../services/smart_split_service.dart';
import '../../widgets/access_request_widget.dart';
import '../../widgets/app_widgets.dart';

/// Recipient View Screen
///
/// Shows a recipient's profile + sorted accounts.
/// User enters an amount and triggers the Smart Split algorithm.
class RecipientScreen extends ConsumerStatefulWidget {
  final User recipient;

  const RecipientScreen({super.key, required this.recipient});

  @override
  ConsumerState<RecipientScreen> createState() => _RecipientScreenState();
}

class _RecipientScreenState extends ConsumerState<RecipientScreen> {
  final _amountCtrl = TextEditingController();
  String? _amountError;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _splitAndNavigate(List<FinancialAccount> accounts) {
    final text = _amountCtrl.text.trim();
    final amount = double.tryParse(text);

    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Enter a valid amount greater than zero');
      return;
    }

    final result = SmartSplitService.split(amount: amount, accounts: accounts);

    if (!result.isSuccess) {
      setState(() => _amountError = result.error);
      return;
    }

    setState(() => _amountError = null);

    Navigator.pushNamed(
      context,
      AppRoutes.transfer,
      arguments: TransferArgs(
        recipient: widget.recipient,
        suggestions: result.suggestions,
        accounts: accounts,
      ),
    );
  }

  Future<void> _showAccessRequestDialog(
    BuildContext context,
    User? currentUser,
  ) async {
    try {
      // Validate before showing dialog
      if (!mounted) return;

      // Get fresh currentUser from provider (don't rely on stale parameter)
      final freshUser = ref.read(authProvider).user;

      // Check if user is authenticated
      if (freshUser == null || freshUser.id.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final (canSend, errorMsg) = await ref
          .read(accessRequestProvider.notifier)
          .canSendRequest(
            requesterId: freshUser.id,
            receiverId: widget.recipient.id,
          );

      if (!canSend) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg ?? 'Cannot send request at this time'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Show dialog
      if (!mounted) return;
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => SendAccessRequestDialog(
          recipientId: widget.recipient.id,
          recipientName: widget.recipient.displayName,
        ),
      );

      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access request sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result == false && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send access request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCancelRequestDialog(
    BuildContext context,
    User? currentUser,
  ) async {
    if (!mounted) return;

    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text(
          'Are you sure you want to cancel this access request? The receiver will no longer see it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Request'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Request', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final success = await ref
            .read(accessRequestProvider.notifier)
            .cancelRequest(
              requesterId: currentUser.id,
              receiverId: widget.recipient.id,
            );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access request cancelled'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh UI
          setState(() {});
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel request'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cache current user at build time
    final currentUser = ref.watch(authProvider).user;

    // Prevent viewing own account - redirect to profile
    if (currentUser != null && currentUser.id == widget.recipient.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.profile);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('View your account from your profile'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
      // Return a loading state while redirecting
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Check if current user has access to recipient's accounts
    final hasAccessAsync = ref.watch(
      hasAccessToAccountsProvider(widget.recipient.id),
    );

    final accountsAsync = ref.watch(
      recipientAccountsProvider(widget.recipient.id),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.recipient.displayName)),
      body: hasAccessAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: ErrorBanner(message: 'Error checking access: $e')),
        data: (hasAccess) {
          // If no access and access is NOT pending/approved, show restricted UI
          if (!hasAccess) {
            return _buildAccessRestrictedUI(context, currentUser);
          }

          // User has access, show accounts
          return accountsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: ErrorBanner(message: 'Could not load accounts: $e'),
            ),
            data: (accounts) {
              // Sort visible accounts by priority before displaying
              final visible = accounts.where((a) => a.isVisible).toList()
                ..sort((a, b) => a.priority.compareTo(b.priority));

              // Check if already approved
              final accessRequestState = ref.watch(accessRequestProvider);
              final sentRequestsAsync = ref.watch(sentRequestsProvider);

              // Get sent requests from either local state or the FutureProvider
              List<AccessRequest>? sentRequests;
              if (accessRequestState.sentRequests.isNotEmpty) {
                sentRequests = accessRequestState.sentRequests;
              } else {
                sentRequests = sentRequestsAsync.value;
              }

              final isAlreadyApproved = sentRequests?.any(
                    (r) =>
                        r.receiverId == widget.recipient.id &&
                        r.status.name == 'approved',
                  ) ??
                  false;

              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  // ── Recipient profile card ────────────────────────────────────
                  _RecipientHeader(recipient: widget.recipient),
                  const SizedBox(height: 24),

                  // ── Accounts ──────────────────────────────────────────────────
                  const Text(
                    'Payment Accounts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (visible.isEmpty)
                    const EmptyState(
                      icon: Icons.block_outlined,
                      title: 'No visible accounts',
                      subtitle: 'This user has no visible payment accounts.',
                    )
                  else
                    ...visible.map((a) => AccountCard(account: a)),

                  const SizedBox(height: 28),

                  // ── Amount Input ──────────────────────────────────────────────
                  AmountInputField(
                    controller: _amountCtrl,
                    errorText: _amountError,
                    onChanged: (_) {
                      if (_amountError != null) {
                        setState(() => _amountError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Split button ──────────────────────────────────────────────
                  PrimaryButton(
                    label: 'Split Automatically',
                    icon: const Icon(Icons.auto_fix_high, color: Colors.white),
                    onPressed: visible.isEmpty
                        ? null
                        : () => _splitAndNavigate(visible),
                  ),
                  const SizedBox(height: 12),

                  // ── Request Access button ─────────────────────────────────────
                  if (!isAlreadyApproved)
                    _buildAccessRequestButton(context, currentUser)
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Access Granted',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Build the access request button with state-aware UI (enabled/disabled/cooldown)
  Widget _buildAccessRequestButton(BuildContext context, User? currentUser) {
    // Watch both local state and the FutureProvider for real-time updates
    final accessRequestState = ref.watch(accessRequestProvider);
    final sentRequestsAsync = ref.watch(sentRequestsProvider);

    // Get sent requests from either local state or the FutureProvider
    List<AccessRequest>? sentRequests;
    bool isLoading = false;

    // Prioritize local state for immediate updates, then fall back to FutureProvider
    if (accessRequestState.sentRequests.isNotEmpty) {
      sentRequests = accessRequestState.sentRequests;
    } else {
      isLoading = sentRequestsAsync.isLoading;
      sentRequests = sentRequestsAsync.value;
    }

    if (sentRequests == null || sentRequests.isEmpty) {
      if (isLoading) {
        return OutlinedButton.icon(
          onPressed: null,
          icon: const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: const Text('Loading...'),
        );
      }
      // No requests found, show request button
      return OutlinedButton.icon(
        onPressed: () => _showAccessRequestDialog(context, currentUser),
        icon: const Icon(Icons.lock_open_outlined),
        label: const Text('Request Account Access'),
      );
    }

    // Find pending or recently rejected request to this recipient
    final lastRequest =
        sentRequests
            .where((r) => r.receiverId == widget.recipient.id)
            .isEmpty
        ? null
        : sentRequests
              .where((r) => r.receiverId == widget.recipient.id)
              .fold<AccessRequest?>(
                null,
                (prev, current) =>
                    prev == null || current.createdAt.isAfter(prev.createdAt)
                    ? current
                    : prev,
              );

    // Check if in cooldown (pending request within 1 hour)
    bool isInCooldown = false;
    int minutesRemaining = 0;

    if (lastRequest != null && lastRequest.status == AccessStatus.pending) {
      final timeSinceRequest = DateTime.now().difference(
        lastRequest.createdAt,
      );
      const cooldownDuration = Duration(hours: 1);

      if (timeSinceRequest < cooldownDuration) {
        isInCooldown = true;
        minutesRemaining =
            (cooldownDuration.inMinutes - timeSinceRequest.inMinutes);
      }
    }

    // If approved, hide button (access already granted)
    if (lastRequest != null && lastRequest.status == AccessStatus.approved) {
      return const SizedBox.shrink();
    }

    // If in cooldown/pending, show cancel option with helpful message
    if (isInCooldown && lastRequest?.status == AccessStatus.pending) {
      return Tooltip(
        message:
            'Request pending approval. Click to cancel or wait $minutesRemaining minutes.',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showCancelRequestDialog(context, currentUser),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel Request'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Your request is pending approval. Click Cancel to revoke it, or wait $minutesRemaining minutes.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Normal state - show enabled button
    return OutlinedButton.icon(
      onPressed: () => _showAccessRequestDialog(context, currentUser),
      icon: const Icon(Icons.lock_open_outlined),
      label: const Text('Request Account Access'),
    );
  }

  /// Build UI when user doesn't have access to recipient's accounts
  Widget _buildAccessRestrictedUI(BuildContext context, User? currentUser) {
    // Check if already approved
    final accessRequestState = ref.watch(accessRequestProvider);
    final sentRequestsAsync = ref.watch(sentRequestsProvider);

    // Get sent requests from either local state or the FutureProvider
    List<AccessRequest>? sentRequests;
    if (accessRequestState.sentRequests.isNotEmpty) {
      sentRequests = accessRequestState.sentRequests;
    } else {
      sentRequests = sentRequestsAsync.value;
    }

    final isAlreadyApproved = sentRequests?.any(
          (r) =>
              r.receiverId == widget.recipient.id &&
              r.status.name == 'approved',
        ) ??
        false;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 24),
            Text(
              'Accounts Not Visible',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.recipient.displayName} has not granted you access to their accounts.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            if (isAlreadyApproved)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Request approved! You can now see their accounts.',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Text(
                    'To send money, request access to their accounts:',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildAccessRequestButtonForRestricted(context, currentUser),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Build the access request button for restricted UI with state-aware UI
  Widget _buildAccessRequestButtonForRestricted(
    BuildContext context,
    User? currentUser,
  ) {
    // Watch both local state and the FutureProvider for real-time updates
    final accessRequestState = ref.watch(accessRequestProvider);
    final sentRequestsAsync = ref.watch(sentRequestsProvider);

    // Get sent requests from either local state or the FutureProvider
    List<AccessRequest>? sentRequests;
    bool isLoading = false;

    // Prioritize local state for immediate updates, then fall back to FutureProvider
    if (accessRequestState.sentRequests.isNotEmpty) {
      sentRequests = accessRequestState.sentRequests;
    } else {
      isLoading = sentRequestsAsync.isLoading;
      sentRequests = sentRequestsAsync.value;
    }

    if (sentRequests == null || sentRequests.isEmpty) {
      if (isLoading) {
        return FilledButton.icon(
          onPressed: null,
          icon: const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          label: const Text('Loading...'),
        );
      }
      // No requests found, show request button
      return FilledButton.icon(
        onPressed: () => _showAccessRequestDialog(context, currentUser),
        icon: const Icon(Icons.lock_open_outlined),
        label: const Text('Request Access'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        ),
      );
    }

    // Find most recent request to this recipient
    final lastRequest =
        sentRequests
            .where((r) => r.receiverId == widget.recipient.id)
            .isEmpty
        ? null
        : sentRequests
              .where((r) => r.receiverId == widget.recipient.id)
              .fold<AccessRequest?>(
                null,
                (prev, current) =>
                    prev == null || current.createdAt.isAfter(prev.createdAt)
                    ? current
                    : prev,
              );

    // Check if in cooldown (pending request within 1 hour)
    bool isInCooldown = false;
    int minutesRemaining = 0;

    if (lastRequest != null && lastRequest.status == AccessStatus.pending) {
      final timeSinceRequest = DateTime.now().difference(
        lastRequest.createdAt,
      );
      const cooldownDuration = Duration(hours: 1);

      if (timeSinceRequest < cooldownDuration) {
        isInCooldown = true;
        minutesRemaining =
            (cooldownDuration.inMinutes - timeSinceRequest.inMinutes);
      }
    }

    // If approved, hide button (access already granted)
    if (lastRequest != null && lastRequest.status == AccessStatus.approved) {
      return const SizedBox.shrink();
    }

    // If in cooldown/pending, show cancel option with helpful message
    if (isInCooldown && lastRequest?.status == AccessStatus.pending) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showCancelRequestDialog(context, currentUser),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel Request'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Your request is pending approval. Click Cancel to revoke it, or wait $minutesRemaining minutes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      );
    }

    // Normal state - show enabled button
    return FilledButton.icon(
      onPressed: () => _showAccessRequestDialog(context, currentUser),
      icon: const Icon(Icons.lock_open_outlined),
      label: const Text('Request Access'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      ),
    );
  }
}

// ─── Recipient header ─────────────────────────────────────────────────────────

class _RecipientHeader extends StatelessWidget {
  final User recipient;

  const _RecipientHeader({required this.recipient});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.surfaceVariant,
              backgroundImage: recipient.avatar != null
                  ? NetworkImage(recipient.avatar!)
                  : null,
              child: recipient.avatar == null
                  ? Text(
                      recipient.displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipient.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${recipient.username}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
