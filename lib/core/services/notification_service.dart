import '../../services/api_client.dart';

class NotificationService {
  final ApiClient apiClient;

  NotificationService(this.apiClient);

  /// Get notifications for user
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final result = await apiClient.get(
        '/items/notifications',
        queryParams: {
          'filter[user][_eq]': userId,
          'sort': '-createdAt',
          'limit': '50',
        },
      );

      if (result['data'] is List) {
        return List<Map<String, dynamic>>.from(result['data']);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Mark notification as read
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    return await apiClient.patch(
      '/items/notifications/$notificationId',
      body: {'isRead': true},
    );
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final notifications = await getNotifications(userId);
      final unreadNotifications = notifications
          .where((n) => n['isRead'] != true)
          .toList();

      for (var notification in unreadNotifications) {
        await markAsRead(notification['id']);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await apiClient.delete('/items/notifications/$notificationId');
  }
}
