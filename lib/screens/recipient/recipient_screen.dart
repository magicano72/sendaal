import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  /// Returns the most recent request to this recipient, or null.
  AccessRequest? _lastRequest(List<AccessRequest>? sentRequests) {
    if (sentRequests == null || sentRequests.isEmpty) return null;
    final matching = sentRequests
        .where((r) => r.receiverId == widget.recipient.id)
        .toList();
    if (matching.isEmpty) return null;
    return matching.fold<AccessRequest?>(
      null,
      (prev, current) =>
          prev == null || current.createdAt.isAfter(prev.createdAt)
          ? current
          : prev,
    );
  }

  /// Consolidate sent requests from local state or FutureProvider.
  List<AccessRequest>? _resolveSentRequests(
    List<AccessRequest> localRequests,
    AsyncValue<List<AccessRequest>> asyncRequests,
  ) {
    if (localRequests.isNotEmpty) return localRequests;
    return asyncRequests.value;
  }

  Future<void> _showAccessRequestDialog(BuildContext context) async {
    if (!mounted) return;

    final freshUser = ref.read(authProvider).user;

    if (freshUser == null || freshUser.id.isEmpty) {
      _showSnackBar(context, 'User not authenticated', Colors.red);
      return;
    }

    // ── Step 1: Check for existing pending request on the backend ──────────
    final (canSend, errorMsg) = await ref
        .read(accessRequestProvider.notifier)
        .canSendRequest(
          requesterId: freshUser.id,
          receiverId: widget.recipient.id,
        );

    if (!canSend) {
      // Show snackbar; do NOT change the button or open dialog.
      if (mounted) {
        _showSnackBar(
          context,
          errorMsg ??
              'You already have a pending request. '
                  'Please wait for approval or cancel it first.',
          Colors.orange,
          duration: const Duration(seconds: 4),
        );
      }
      return;
    }

    // ── Step 2: No pending request – show dialog ────────────────────────────
    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SendAccessRequestDialog(
        recipientId: widget.recipient.id,
        recipientName: widget.recipient.displayName,
      ),
    );

    if (!mounted) return;

    if (result == true) {
      // Force refresh so button switches to "Cancel Request" immediately.
      ref.invalidate(sentRequestsProvider);
      _showSnackBar(context, 'Access request sent successfully', Colors.green);
    } else if (result == false) {
      _showSnackBar(context, 'Failed to send access request', Colors.red);
    }
    // result == null ⇒ user dismissed or dialog handled duplicate internally.
  }

  Future<void> _showCancelRequestDialog(BuildContext context) async {
    if (!mounted) return;

    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) {
      _showSnackBar(context, 'User not authenticated', Colors.red);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text(
          'Are you sure you want to cancel this access request? '
          'The receiver will no longer see it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Request'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cancel Request',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final success = await ref
          .read(accessRequestProvider.notifier)
          .cancelRequest(
            requesterId: currentUser.id,
            receiverId: widget.recipient.id,
          );

      if (!mounted) return;

      if (success) {
        // Invalidate so button switches back to "Request Access" immediately.
        ref.invalidate(sentRequestsProvider);
        _showSnackBar(context, 'Access request cancelled', Colors.green);
      } else {
        _showSnackBar(context, 'Failed to cancel request', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, 'Error: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    Color color, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;

    // Prevent viewing own account – redirect to profile.
    if (currentUser != null && currentUser.id == widget.recipient.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.profile);
          _showSnackBar(
            context,
            'View your account from your profile',
            Colors.blue,
          );
        }
      });
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          if (!hasAccess) {
            return _buildAccessRestrictedUI(context, currentUser);
          }

          return accountsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: ErrorBanner(message: 'Could not load accounts: $e'),
            ),
            data: (accounts) {
              final visible = accounts.where((a) => a.isVisible).toList()
                ..sort((a, b) => a.priority.compareTo(b.priority));

              return _buildAccessGrantedBody(context, visible);
            },
          );
        },
      ),
    );
  }

  // ── Body when access is granted ──────────────────────────────────────────

  Widget _buildAccessGrantedBody(
    BuildContext context,
    List<FinancialAccount> visible,
  ) {
    // Single source of truth for request state.
    final accessState = ref.watch(accessRequestProvider);
    final sentRequestsAsync = ref.watch(sentRequestsProvider);

    final sentRequests = _resolveSentRequests(
      accessState.sentRequests,
      sentRequestsAsync,
    );
    final lastRequest = _lastRequest(sentRequests);
    final isApproved = lastRequest?.status == AccessStatus.approved;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _RecipientHeader(recipient: widget.recipient),
        const SizedBox(height: 24),

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

        AmountInputField(
          controller: _amountCtrl,
          errorText: _amountError,
          onChanged: (_) {
            if (_amountError != null) setState(() => _amountError = null);
          },
        ),
        const SizedBox(height: 20),

        PrimaryButton(
          label: 'Split Automatically',
          icon: const Icon(Icons.auto_fix_high, color: Colors.white),
          onPressed: visible.isEmpty ? null : () => _splitAndNavigate(visible),
        ),
        const SizedBox(height: 12),

        // ── Access button / approved badge ────────────────────────────────
        if (isApproved)
          _buildApprovedBadge()
        else
          _buildRequestButton(
            context,
            lastRequest,
            sentRequestsAsync.isLoading,
          ),
      ],
    );
  }

  // ── Restricted UI (no access yet) ────────────────────────────────────────

  Widget _buildAccessRestrictedUI(BuildContext context, User? currentUser) {
    final accessState = ref.watch(accessRequestProvider);
    final sentRequestsAsync = ref.watch(sentRequestsProvider);

    final sentRequests = _resolveSentRequests(
      accessState.sentRequests,
      sentRequestsAsync,
    );
    final lastRequest = _lastRequest(sentRequests);
    final isApproved = lastRequest?.status == AccessStatus.approved;

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
            if (isApproved)
              _buildApprovedBanner()
            else ...[
              Text(
                'To send money, request access to their accounts:',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildRequestButton(
                context,
                lastRequest,
                sentRequestsAsync.isLoading,
                filled: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Shared button builder ─────────────────────────────────────────────────

  /// Renders the correct button variant based on [lastRequest] status.
  ///
  /// [filled] – use FilledButton style (restricted UI); otherwise OutlinedButton.
  Widget _buildRequestButton(
    BuildContext context,
    AccessRequest? lastRequest,
    bool isLoading, {
    bool filled = false,
  }) {
    // ── Loading ──────────────────────────────────────────────────────────────
    if (isLoading && lastRequest == null) {
      final loadingIndicator = SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: filled
              ? const AlwaysStoppedAnimation<Color>(Colors.white)
              : null,
        ),
      );
      return filled
          ? FilledButton.icon(
              onPressed: null,
              icon: loadingIndicator,
              label: const Text('Loading...'),
            )
          : OutlinedButton.icon(
              onPressed: null,
              icon: loadingIndicator,
              label: const Text('Loading...'),
            );
    }

    // ── Pending – show Cancel button ─────────────────────────────────────────
    if (lastRequest?.status == AccessStatus.pending) {
      return Tooltip(
        textStyle: Theme.of(context).textTheme.bodySmall,
        message:
            'Request pending approval. Tap to cancel if you no longer need it.',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showCancelRequestDialog(context),
              icon: const Icon(Icons.close),
              label: const Text('Cancel Request'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
            const SizedBox(height: 8),
            _pendingNotice(context),
          ],
        ),
      );
    }

    // ── Default – Request Access ──────────────────────────────────────────────
    if (filled) {
      return FilledButton.icon(
        onPressed: () => _showAccessRequestDialog(context),
        icon: const Icon(Icons.lock_open_outlined),
        label: const Text('Request Access'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _showAccessRequestDialog(context),
      icon: const Icon(Icons.lock_open_outlined),
      label: const Text('Request Account Access'),
    );
  }

  Widget _pendingNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Your request is pending approval. Tap Cancel to revoke it.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.orange.shade700),
      ),
    );
  }

  Widget _buildApprovedBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text(
            'Access Granted',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedBanner() {
    return Container(
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
    );
  }
}

// ─── Recipient header ─────────────────────────────────────────────────────────
class _RecipientHeader extends StatelessWidget {
  final User recipient;

  const _RecipientHeader({required this.recipient});

  @override
  Widget build(BuildContext context) {
    // ── Resolve avatar URL once, up front ──────────────────────────────────
    final String base = dotenv.env['BASE_URL'] ?? '';
    final String? raw = recipient.avatar;
    final String? avatarUrl = (raw != null && raw.isNotEmpty)
        ? (raw.startsWith('http') ? raw : '$base/assets/$raw')
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.surfaceVariant,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      recipient.initials,
                      style: const TextStyle(
                        fontSize: 16,
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
