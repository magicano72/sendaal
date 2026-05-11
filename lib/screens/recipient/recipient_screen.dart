import 'package:Sendaal/models/access_request_model.dart';
import 'package:Sendaal/providers/access_request_provider.dart';
import 'package:Sendaal/providers/auth_provider.dart';
import 'package:Sendaal/widgets/account_card.dart';
import 'package:Sendaal/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/models/user_model.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_account_model.dart';
import '../../providers/account_provider.dart';
import '../../services/smart_split_service.dart';
import '../../widgets/access_request_widget.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/user_avatar.dart';
import '../requests/status_banar.dart';

String _preferredName(User user) {
  if (user.firstName?.isNotEmpty ?? false) return user.firstName!;
  if (user.displayName.isNotEmpty) return user.displayName;
  return user.username;
}

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
  bool _isRequestingAccess = false;
  bool _isRevocationProcessing = false;
  String? _selectedCurrency;

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
    if (accounts.isEmpty) {
      setState(() => _amountError = 'No accounts available for this currency');
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
    // Prioritize any pending request regardless of date precision.
    final pending = matching.where((r) => r.status == AccessStatus.pending);
    if (pending.isNotEmpty) {
      return pending.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
    }
    // Otherwise pick the most recent by creation date.
    return matching.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
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

    setState(() => _isRequestingAccess = true);
    try {
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
          recipientName: _preferredName(widget.recipient),
        ),
      );

      if (!mounted) return;

      if (result == true) {
        // Force refresh so button switches to "Cancel Request" immediately.
        ref.invalidate(sentRequestsProvider);
        await ref
            .read(accessRequestProvider.notifier)
            .loadSentRequests(freshUser.id);
      } else if (result == false) {
        //  AppSnackBar.error(context, 'Failed to send access request');
      }
      // result == null ⇒ user dismissed or dialog handled duplicate internally.
    } finally {
      if (mounted) {
        setState(() => _isRequestingAccess = false);
      }
    }
  }

  Future<void> _showCancelRequestDialog(BuildContext context) async {
    if (!mounted) return;

    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) {
      AppSnackBar.error(context, 'User not authenticated');
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
        AppSnackBar.success(context, 'Access request cancelled');
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
    final latestRequestAsync = currentUser == null
        ? const AsyncValue<AccessRequest?>.data(null)
        : ref.watch(
            latestRequestBetweenProvider((currentUser.id, widget.recipient.id)),
          );

    // Prevent viewing own account - redirect to profile.
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

    return Scaffold(
      appBar: AppBar(title: Text(_preferredName(widget.recipient))),
      body: latestRequestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: ErrorBanner(message: 'Could not load status: $e')),
        data: (latest) {
          final isRevoked = latest?.isRevoked == true;
          final isRevoker =
              isRevoked &&
              currentUser != null &&
              latest?.revokerId == currentUser.id;

          if (isRevoked && latest != null) {
            return _buildRevokedRecipientUI(
              context,
              request: latest,
              isRevoker: isRevoker,
            );
          }

          final accountsAsync = ref.watch(
            approvedAccountsProvider(widget.recipient.id),
          );

          return accountsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: ErrorBanner(message: 'Could not load accounts: $e'),
            ),
            data: (result) {
              if (!result.hasAccess) {
                return _buildAccessRestrictedUI(context, currentUser);
              }

              final visible = result.accounts
                  .where((a) => a.isVisible)
                  .toList();
              const order = {'high': 0, 'medium': 1, 'low': 2};
              visible.sort((a, b) {
                final pa = order[a.priority.name] ?? 1;
                final pb = order[b.priority.name] ?? 1;
                if (pa != pb) return pa.compareTo(pb);
                final ca =
                    a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                final cb =
                    b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                return ca.compareTo(cb);
              });

              final currencies = <String>[];
              for (final account in visible) {
                final currency = (account.currency?.isNotEmpty == true)
                    ? account.currency!
                    : 'EGP';
                if (!currencies.contains(currency)) {
                  currencies.add(currency);
                }
              }

              var selected = _selectedCurrency;
              if (currencies.isNotEmpty &&
                  (selected == null || !currencies.contains(selected))) {
                selected = currencies.first;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _selectedCurrency = selected);
                });
              }

              final filtered = selected == null
                  ? <FinancialAccount>[]
                  : visible
                        .where(
                          (a) =>
                              (a.currency?.isNotEmpty == true
                                  ? a.currency!
                                  : 'EGP') ==
                              selected,
                        )
                        .toList();

              return _buildAccessGrantedBody(
                context,
                visible: visible,
                filtered: filtered,
                currencies: currencies,
                selectedCurrency: selected,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRevokedRecipientUI(
    BuildContext context, {
    required AccessRequest request,
    required bool isRevoker,
  }) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      children: [
        _RecipientHeader(recipient: widget.recipient),
        SizedBox(height: 12.h),
        StatusBanner(status: request.status),
        SizedBox(height: 12.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Access Denied',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.redAccent,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  isRevoker
                      ? 'You revoked this connection. Cancel revoke to restore access and visibility.'
                      : 'This connection has been revoked. You cannot view any accounts.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isRevoker) ...[
          SizedBox(height: 12.h),
          FilledButton(
            onPressed: _isRevocationProcessing
                ? null
                : () => _cancelRevokeFromRecipient(request.id),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              backgroundColor: AppTheme.primary,
            ),
            child: _isRevocationProcessing
                ? SizedBox(
                    height: 18.r,
                    width: 18.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Cancel Revoke'),
          ),
        ],
      ],
    );
  }

  Future<void> _cancelRevokeFromRecipient(String requestId) async {
    if (_isRevocationProcessing) return;
    setState(() => _isRevocationProcessing = true);

    final updated = await ref
        .read(accessRequestProvider.notifier)
        .cancelRevoke(requestId);

    if (!mounted) return;

    setState(() => _isRevocationProcessing = false);

    if (updated != null) {
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        await Future.wait([
          ref
              .read(accessRequestProvider.notifier)
              .loadSentRequests(currentUser.id),
          ref
              .read(accessRequestProvider.notifier)
              .loadReceivedRequests(currentUser.id),
        ]);
      }

      ref.invalidate(
        latestRequestBetweenProvider((
          currentUser?.id ?? '',
          widget.recipient.id,
        )),
      );
      ref.invalidate(approvedAccountsProvider(widget.recipient.id));

      if (mounted) {
        AppSnackBar.success(context, 'Access restored');
      }
    } else {
      final err =
          ref.read(accessRequestProvider).error ?? 'Failed to cancel revoke';
      AppSnackBar.error(context, err);
    }
  }

  // ── Body when access is granted ──────────────────────────────────────────

  Widget _buildAccessGrantedBody(
    BuildContext context, {
    required List<FinancialAccount> visible,
    required List<FinancialAccount> filtered,
    required List<String> currencies,
    required String? selectedCurrency,
  }) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      children: [
        _RecipientHeader(recipient: widget.recipient),
        SizedBox(height: 24.h),

        Text(
          'Payment Accounts',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 10.h),

        if (currencies.isNotEmpty)
          DropdownButtonFormField<String>(
            value: selectedCurrency,
            items: currencies
                .map(
                  (c) => DropdownMenuItem<String>(
                    value: c,
                    child: Text(
                      c,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                )
                .toList(),
            decoration: InputDecoration(
              labelText: 'Currency',
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            onChanged: (value) {
              setState(() {
                _selectedCurrency = value;
                _amountError = null;
              });
            },
          ),
        if (currencies.isNotEmpty) SizedBox(height: 10.h),

        if (visible.isEmpty)
          const EmptyState(
            icon: Icons.block_outlined,
            title: 'No visible accounts',
            subtitle: 'This user has no visible payment accounts.',
          )
        else if (filtered.isEmpty)
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade800,
                  size: 20.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'No accounts available for this currency.',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...filtered.map((a) => AccountCard(account: a)),

        SizedBox(height: 28.h),

        AmountInputField(
          controller: _amountCtrl,
          errorText: _amountError,
          currency: selectedCurrency ?? 'EGP',
          onChanged: (_) {
            if (_amountError != null) setState(() => _amountError = null);
          },
        ),
        SizedBox(height: 20.h),

        PrimaryButton(
          label: 'Split Automatically',
          icon: Icon(Icons.auto_fix_high, color: Colors.white, size: 20.r),
          onPressed: filtered.isEmpty
              ? null
              : () => _splitAndNavigate(filtered),
        ),
        SizedBox(height: 12.h),

        // ── Access button / approved badge ────────────────────────────────
        // if (isApproved)
        //   _buildApprovedBadge()
        // else
        //   _buildRequestButton(
        //     context,
        //     lastRequest,
        //     sentRequestsAsync.isLoading,
        //     rejectionCountAsync: rejectionCountAsync,
        //   ),
      ],
    );
  }

  // ── Restricted UI (no access yet) ────────────────────────────────────────

  Widget _buildAccessRestrictedUI(BuildContext context, User? currentUser) {
    final accessState = ref.watch(accessRequestProvider);
    final sentRequestsAsync = ref.watch(sentRequestsProvider);
    final rejectionCountAsync = currentUser == null
        ? const AsyncValue.data(0)
        : ref.watch(
            rejectionCountProvider((currentUser.id, widget.recipient.id)),
          );

    final sentRequests = _resolveSentRequests(
      accessState.sentRequests,
      sentRequestsAsync,
    );
    final lastRequest = _lastRequest(sentRequests);
    final isApproved = lastRequest?.status == AccessStatus.approved;

    final isPending = lastRequest?.status == AccessStatus.pending;

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      children: [
        _RecipientHeader(recipient: widget.recipient),
        SizedBox(height: 16.h),
        _buildRestrictedHeroCard(context, isPending: isPending),
        SizedBox(height: 16.h),
        if (isApproved)
          _buildApprovedBanner()
        else ...[
          _buildAccessGuidanceCard(context, isPending: isPending),
          SizedBox(height: 18.h),
          _buildRequestButton(
            context,
            lastRequest,
            sentRequestsAsync.isLoading,
            rejectionCountAsync: rejectionCountAsync,
            filled: true,
          ),
        ],
      ],
    );
  }

  // ── Shared button builder ─────────────────────────────────────────────────

  /// Renders the correct button variant based on [lastRequest] status.
  ///
  /// [filled] – use FilledButton style (restricted UI); otherwise OutlinedButton.
  Widget _buildRestrictedHeroCard(
    BuildContext context, {
    required bool isPending,
  }) {
    final accentColor = isPending ? AppColors.warning : AppTheme.primary;
    final title = isPending ? 'Request Sent' : 'Accounts Not Visible';
    final description = isPending
        ? 'We sent your access request to ${_preferredName(widget.recipient)}. Their visible accounts will appear here automatically once they approve it.'
        : '${_preferredName(widget.recipient)} keeps their accounts private until they approve your request.';

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: isPending ? 0.18 : 0.12),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPending)
            const StatusChip(status: AccessStatus.pending)
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Text(
                'Private Accounts',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          SizedBox(height: 18.h),
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPending ? Icons.mark_email_unread_outlined : Icons.lock_outline,
              size: 30.r,
              color: accentColor,
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 18.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: accentColor.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                Icon(
                  isPending
                      ? Icons.hourglass_top_rounded
                      : Icons.visibility_off_outlined,
                  size: 18.r,
                  color: accentColor,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    isPending
                        ? 'Approval is still pending. You can cancel the request any time before it is accepted.'
                        : 'Request access to unlock available payment accounts for future transfers.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessGuidanceCard(
    BuildContext context, {
    required bool isPending,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPending ? 'What Happens Next' : 'How Access Works',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 14.h),
            _buildGuidanceRow(
              context,
              icon: isPending
                  ? Icons.notifications_active_outlined
                  : Icons.send_outlined,
              title: isPending
                  ? 'The recipient reviews your request'
                  : 'Send one request to get started',
              description: isPending
                  ? '${_preferredName(widget.recipient)} will see your request in their access inbox.'
                  : 'Ask ${_preferredName(widget.recipient)} for permission before sending money.',
            ),
            SizedBox(height: 12.h),
            _buildGuidanceRow(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: isPending
                  ? 'Accounts appear automatically after approval'
                  : 'Only approved accounts become visible',
              description: isPending
                  ? 'You do not need to refresh this flow manually once access is granted.'
                  : 'Sendaal only shows the payment accounts they decide to share with you.',
            ),
            SizedBox(height: 12.h),
            _buildGuidanceRow(
              context,
              icon: isPending
                  ? Icons.close_rounded
                  : Icons.verified_user_outlined,
              title: isPending
                  ? 'Need to stop it? Cancel anytime'
                  : 'Access keeps transfers clearer and safer',
              description: isPending
                  ? 'If you sent it by mistake, cancel the request before it is approved.'
                  : 'Once approved, you can choose an account directly and split payments with confidence.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, size: 20.r, color: AppTheme.primary),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Renders the correct button variant based on [lastRequest] status.
  ///
  /// [filled] uses the primary button treatment for the restricted state.
  Widget _buildRequestButton(
    BuildContext context,
    AccessRequest? lastRequest,
    bool isLoading, {
    AsyncValue<int> rejectionCountAsync = const AsyncValue.data(0),
    bool filled = false,
  }) {
    // ── Loading ──────────────────────────────────────────────────────────────
    if (_isRequestingAccess || (isLoading && lastRequest == null)) {
      return _buildLoadingButton(filled);
    }

    // ── Pending – show Cancel button ─────────────────────────────────────────
    if (lastRequest?.status == AccessStatus.pending) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showCancelRequestDialog(context),
          icon: Icon(Icons.close_rounded, size: 18.r),
          label: Text('Cancel Request', style: TextStyle(fontSize: 14.sp)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.error,
            side: BorderSide(color: AppTheme.error.withValues(alpha: 0.24)),
            backgroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        ),
      );
    }

    final rejectionCount = rejectionCountAsync.value ?? 0;
    final rejectionLoading = rejectionCountAsync.isLoading;

    // ── Access denied after 3 rejections ────────────────────────────────────
    if (rejectionLoading) {
      return _buildLoadingButton(filled, label: 'Checking access...');
    }
    if (rejectionCount >= 3) {
      return _buildAccessDenied(filled);
    }

    // ── Default – Request Access ──────────────────────────────────────────────
    if (filled) {
      return FilledButton.icon(
        onPressed: () => _showAccessRequestDialog(context),
        icon: Icon(Icons.lock_open_outlined, size: 18.r),
        label: Text('Request Access', style: TextStyle(fontSize: 14.sp)),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _showAccessRequestDialog(context),
      icon: Icon(Icons.lock_open_outlined, size: 18.r),
      label: Text('Request Account Access', style: TextStyle(fontSize: 14.sp)),
    );
  }

  Widget _buildLoadingButton(bool filled, {String label = 'Loading...'}) {
    final loadingIndicator = SizedBox(
      height: 18.w,
      width: 18.w,
      child: CircularProgressIndicator(
        strokeWidth: 2.w,
        valueColor: filled
            ? const AlwaysStoppedAnimation<Color>(Colors.white)
            : null,
      ),
    );
    return filled
        ? FilledButton.icon(
            onPressed: null,
            icon: loadingIndicator,
            label: Text(label, style: TextStyle(fontSize: 14.sp)),
          )
        : OutlinedButton.icon(
            onPressed: null,
            icon: loadingIndicator,
            label: Text(label, style: TextStyle(fontSize: 14.sp)),
          );
  }

  Widget _buildAccessDenied(bool filled) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.block, size: 18.r),
        SizedBox(width: 8.w),
        Text('Access Denied', style: TextStyle(fontSize: 14.sp)),
      ],
    );

    return filled
        ? FilledButton(
            onPressed: null,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.grey.shade400,
            ),
            child: child,
          )
        : OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: child,
          );
  }

  Widget _buildApprovedBanner() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 18.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Request approved! You can now see their accounts.',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
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
    // 🔍 DEBUG: trace every value before touching NetworkImage
    debugPrint('╔══ _RecipientHeader.build() ════════════════');
    debugPrint('║  recipient.avatar    : ${recipient.avatar}');
    debugPrint('║  recipient.avatarUrl : ${recipient.avatarUrl}');
    debugPrint('╚════════════════════════════════════════════');

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            UserAvatar(
              avatarUrl: recipient.avatarUrl,
              name: _preferredName(recipient),
              radius: 30.r,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              textColor: AppTheme.primary,
              textStyle: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _preferredName(recipient),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '@${recipient.username}',
                    style: TextStyle(
                      fontSize: 13.sp,
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
