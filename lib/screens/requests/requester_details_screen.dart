import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sendaal/screens/requests/status_banar.dart';

import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../models/access_request_model.dart';
import '../../providers/access_request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_widgets.dart';

enum _ActionType { approve, reject }

/// Displays full requester details fetched by ID, with status actions.
class RequesterDetailsScreen extends ConsumerStatefulWidget {
  final AccessRequest request;

  const RequesterDetailsScreen({super.key, required this.request});

  @override
  ConsumerState<RequesterDetailsScreen> createState() =>
      _RequesterDetailsScreenState();
}

class _RequesterDetailsScreenState
    extends ConsumerState<RequesterDetailsScreen> {
  bool _isProcessing = false;
  _ActionType? _pendingAction;
  AccessStatus? _localStatus;

  AccessRequest get _request =>
      widget.request.copyWith(status: _localStatus ?? widget.request.status);

  @override
  Widget build(BuildContext context) {
    final requesterId = _request.requesterId;
    final currentUser = ref.watch(authProvider).user;
    final isReceiver = currentUser?.id == _request.receiverId;
    final canAct = isReceiver && _request.status == AccessStatus.pending;

    final userAsync = ref.watch(userProvider(requesterId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requester Details'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: StatusChip(status: _request.status)),
          ),
        ],
      ),
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(20),
            child: ErrorBanner(
              message: 'Unable to load requester details.',
              onRetry: () => ref.refresh(userProvider(requesterId)),
            ),
          ),
          data: (user) => _RequesterDetailsBody(
            user: user,
            request: _request,
            canAct: canAct,
            isProcessing: _isProcessing,
            pendingAction: _pendingAction,
            onApprove: () => _handleAction(approve: true),
            onReject: () => _handleAction(approve: false),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction({required bool approve}) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _pendingAction = approve ? _ActionType.approve : _ActionType.reject;
    });

    final notifier = ref.read(accessRequestProvider.notifier);
    final success = approve
        ? await notifier.approveRequest(_request.id)
        : await notifier.rejectRequest(_request.id);

    if (!mounted) return;

    if (success) {
      setState(() {
        _localStatus = approve ? AccessStatus.approved : AccessStatus.rejected;
        _isProcessing = false;
        _pendingAction = null;
      });

      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        await Future.wait([
          notifier.loadReceivedRequests(currentUser.id),
          notifier.loadSentRequests(currentUser.id),
        ]);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve ? 'Access request approved!' : 'Access request rejected',
          ),
          backgroundColor: approve ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final errorMsg =
          ref.read(accessRequestProvider).error ?? 'Something went wrong';
      setState(() {
        _isProcessing = false;
        _pendingAction = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _RequesterDetailsBody extends StatelessWidget {
  final User user;
  final AccessRequest request;
  final bool canAct;
  final bool isProcessing;
  final _ActionType? pendingAction;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  const _RequesterDetailsBody({
    required this.user,
    required this.request,
    required this.canAct,
    required this.isProcessing,
    required this.pendingAction,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;
    final phone = (user.phone ?? '').trim();
    final email = (user.email ?? '').trim();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.surfaceVariant,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    user.initials,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user.displayName.isNotEmpty ? user.displayName : 'Unknown user',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            '@${user.username}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Full Name',
                  value: user.displayName.isNotEmpty
                      ? user.displayName
                      : 'Not provided',
                ),
                const Divider(height: 20),
                _InfoRow(
                  icon: Icons.alternate_email,
                  label: 'Username',
                  value: '@${user.username}',
                ),
                const Divider(height: 20),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  value: phone.isNotEmpty ? phone : 'Not provided',
                ),
                const Divider(height: 20),
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: email.isNotEmpty ? email : 'Not provided',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        StatusBanner(status: request.status),
        if (canAct) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : onReject,
                  icon: pendingAction == _ActionType.reject && isProcessing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.close, size: 18),
                  label: Text(
                    pendingAction == _ActionType.reject && isProcessing
                        ? 'Rejecting...'
                        : 'Reject',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isProcessing ? null : onApprove,
                  icon: pendingAction == _ActionType.approve && isProcessing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(
                    pendingAction == _ActionType.approve && isProcessing
                        ? 'Approving...'
                        : 'Approve',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (!canAct) ...[
          const SizedBox(height: 12),
          Text(
            'Only the receiver can change the request status.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Only information you are allowed to see is shown here.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
