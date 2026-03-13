import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../models/access_request_model.dart';
import '../providers/access_request_provider.dart';
import '../providers/user_provider.dart';
import 'shimmer_widgets.dart';

/// Compact card to display access request on home screen
class AccessRequestCard extends ConsumerWidget {
  final AccessRequest request;
  final bool isReceived; // True if receiver viewing, false if requester viewing

  const AccessRequestCard({
    super.key,
    required this.request,
    this.isReceived = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = request.status.name == 'pending';
    final statusColor = _getStatusColor();

    // Fetch user info (requester if received, receiver if sent)
    final userIdToFetch = isReceived ? request.requesterId : request.receiverId;
    final userAsync = ref.watch(userProvider(userIdToFetch));
    final labelText = isReceived ? 'From: @' : 'To: @';

    return userAsync.when(
      loading: () => const ShimmerCard(height: 140),
      error: (error, stackTrace) {
        // Fallback UI if user fetch fails
        return _buildCard(
          context,
          ref,
          userName: 'User ${userIdToFetch.substring(0, 8)}...',
          isPending: isPending,
          statusColor: statusColor,
          isReceived: isReceived,
          labelText: labelText,
        );
      },
      data: (user) => _buildCard(
        context,
        ref,
        userName: user.username,
        isPending: isPending,
        statusColor: statusColor,
        isReceived: isReceived,
        labelText: labelText,
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref, {
    required String userName,
    required bool isPending,
    required Color statusColor,
    required bool isReceived,
    required String labelText,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReceived ? 'Access Request' : 'Request Status',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$labelText$userName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    request.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date row
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(request.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons - ONLY show if received and pending
            if (isReceived && isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectRequest(context, ref, request.id),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text(
                        'Reject',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          _approveRequest(context, ref, request.id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text(
                        'Approve',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  request.status.name == 'approved' ? '✓ Access Granted' : '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: request.status.name == 'approved'
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (request.status.name) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final requestDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (requestDate == today) {
      return 'Today';
    } else if (requestDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${requestDate.year}-${requestDate.month.toString().padLeft(2, '0')}-${requestDate.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _approveRequest(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    final notifier = ref.read(accessRequestProvider.notifier);
    final success = await notifier.approveRequest(requestId);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access request approved!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (!success && context.mounted) {
      final errorMsg = ref.read(accessRequestProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'Failed to approve request'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _rejectRequest(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    final notifier = ref.read(accessRequestProvider.notifier);
    final success = await notifier.rejectRequest(requestId);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access request rejected'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (!success && context.mounted) {
      final errorMsg = ref.read(accessRequestProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'Failed to reject request'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
