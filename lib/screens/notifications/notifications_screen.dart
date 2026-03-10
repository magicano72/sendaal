import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

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
          }
        },
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(NotificationsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: ErrorBanner(
          message: state.error!,
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

    if (state.notifications.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none_outlined,
        title: 'No notifications yet',
        subtitle: 'You\'ll see payment requests and updates here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final notification = state.notifications[i];
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
      },
    );
  }
}
