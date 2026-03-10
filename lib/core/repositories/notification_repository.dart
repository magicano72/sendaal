import '../error/exceptions.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationRepository {
  final NotificationService notificationService;

  NotificationRepository(this.notificationService);

  Future<List<Notification>> getUserNotifications(String userId) async {
    try {
      final responses = await notificationService.getNotifications(userId);
      return responses.map((data) => Notification.fromJson(data)).toList();
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch notifications: ${e.toString()}',
      );
    }
  }

  Future<Notification> markNotificationAsRead(String notificationId) async {
    try {
      final response = await notificationService.markAsRead(notificationId);
      return Notification.fromJson(response);
    } catch (e) {
      throw ApiException(
        message: 'Failed to update notification: ${e.toString()}',
      );
    }
  }
}
