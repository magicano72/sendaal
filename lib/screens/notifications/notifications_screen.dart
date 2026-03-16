import 'package:Sendaal/widgets/access_request_widget.dart'
    show AccessRequestTile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../providers/access_request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/app_widgets.dart';

/// Notifications Screen — displays all user notifications with read state
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(notificationsProvider.notifier).loadNotifications(user.id);
        ref.read(accessRequestProvider.notifier).loadReceivedRequests(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final accessRequests = ref.watch(accessRequestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () {
                // Mark all unread as read
                for (final n in state.notifications) {
                  if (!n.isRead) {
                    ref.read(notificationsProvider.notifier).markAsRead(n.id);
                  }
                }
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final user = ref.read(authProvider).user;
          if (user != null) {
            await ref
                .read(notificationsProvider.notifier)
                .loadNotifications(user.id);
            await ref
                .read(accessRequestProvider.notifier)
                .loadReceivedRequests(user.id);
          }
        },
        child: _buildBody(state, accessRequests),
      ),
    );
  }

  Widget _buildBody(
    NotificationsState notifState,
    AccessRequestsState accessState,
  ) {
    if (notifState.isLoading || accessState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifState.error != null) {
      return Padding(
        padding: EdgeInsets.all(20.w),
        child: ErrorBanner(
          message: notifState.error!,
          onRetry: () {
            final user = ref.read(authProvider).user;
            if (user != null) {
              ref
                  .read(notificationsProvider.notifier)
                  .loadNotifications(user.id);
            }
          },
        ),
      );
    }

    // No items at all
    if (notifState.notifications.isEmpty &&
        accessState.receivedRequests.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none_outlined,
        title: 'No notifications yet',
        subtitle: 'You\'ll see payment requests and updates here.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount:
          accessState.receivedRequests.length +
          notifState.notifications.length +
          (accessState.receivedRequests.isNotEmpty ? 1 : 0),
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, i) {
        // Section header for access requests
        if (i == 0 && accessState.receivedRequests.isNotEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              'Access Requests',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          );
        }

        // Access requests
        if (accessState.receivedRequests.isNotEmpty) {
          if (i > 0 && i <= accessState.receivedRequests.length) {
            final request = accessState.receivedRequests[i - 1];
            return AccessRequestTile(request: request);
          }

          // Notifications section header
          if (i == accessState.receivedRequests.length + 1 &&
              notifState.notifications.isNotEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'Notifications',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            );
          }

          // Notifications
          if (i > accessState.receivedRequests.length + 1) {
            final notifIndex = i - accessState.receivedRequests.length - 2;
            if (notifIndex < notifState.notifications.length) {
              final notification = notifState.notifications[notifIndex];
              return NotificationTile(
                notification: notification,
                onTap: () {
                  if (!notification.isRead) {
                    ref
                        .read(notificationsProvider.notifier)
                        .markAsRead(notification.id);
                  }
                },
              );
            }
          }
        } else {
          // No access requests, just show notifications
          if (notifState.notifications.isNotEmpty &&
              i < notifState.notifications.length) {
            final notification = notifState.notifications[i];
            return NotificationTile(
              notification: notification,
              onTap: () {
                if (!notification.isRead) {
                  ref
                      .read(notificationsProvider.notifier)
                      .markAsRead(notification.id);
                }
              },
            );
          }
        }

        return const SizedBox.shrink();
      },
    );
  }
}
