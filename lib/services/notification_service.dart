import '../core/models/notification_model.dart';
import 'api_client.dart';
import 'endpoint.dart';

/// Handles notification fetching and read-state updates
class NotificationService {
  final ApiClient _api;

  NotificationService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient.instance;

  /// Fetch all notifications for a user, sorted newest first
  Future<List<Notification>> getNotifications(String userId) async {
    final response = await _api.get(
      Endpoints.notifications,
      queryParams: {'filter[user][_eq]': userId, 'sort': '-date_created'},
    );
    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => Notification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Mark a single notification as read
  Future<Notification> markAsRead(String notificationId) async {
    final response = await _api.patch(
      Endpoints.notificationById(notificationId),
      body: {'is_read': true},
    );
    return Notification.fromJson(response['data'] as Map<String, dynamic>);
  }
}
