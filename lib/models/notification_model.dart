import '../utils/date_utils.dart';

/// Notification types supported by Sendaal
enum NotificationType {
  access_request,
  access_approved,
  system;

  static NotificationType fromString(String value) =>
      NotificationType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => NotificationType.system,
      );
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id']?.toString() ?? '',
        userId: json['user']?.toString() ?? json['userId']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        type: NotificationType.fromString(json['type']?.toString() ?? 'system'),
        isRead: json['is_read'] == true || json['isRead'] == true,
        createdAt: parseDirectusDateOrNow(
          json['date_created']?.toString() ?? json['createdAt']?.toString(),
        ),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user': userId,
    'title': title,
    'body': body,
    'type': type.name,
    'is_read': isRead,
    'date_created': createdAt.toIso8601String(),
  };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id,
    userId: userId,
    title: title,
    body: body,
    type: type,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}
