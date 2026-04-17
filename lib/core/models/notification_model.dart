class Notification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // access_request, access_approved, system
  final bool isRead;
  final String createdAt;
  final String? relatedId; // ID of related request or object

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedId,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString() ?? 'system';
    final rawTitle = json['title']?.toString() ?? '';
    final rawBody = json['body']?.toString() ?? '';

    // Provide sensible defaults based on notification type if title/body are empty
    String title = rawTitle;
    String body = rawBody;

    if (title.isEmpty) {
      switch (rawType) {
        case 'access_request':
          title = 'Access Request';
          break;
        case 'access_approved':
          title = 'Access Approved';
          break;
        case 'system':
        default:
          title = 'Notification';
          break;
      }
    }

    if (body.isEmpty) {
      body = 'You have a new notification';
    }

    return Notification(
      id: json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? json['userId']?.toString() ?? '',
      title: title,
      body: body,
      type: rawType,
      isRead: json['is_read'] == true || json['isRead'] == true,
      createdAt:
          json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',
      relatedId:
          json['related_id']?.toString() ?? json['relatedId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user': userId,
    'title': title,
    'body': body,
    'type': type,
    'is_read': isRead,
    'created_at': createdAt,
    'related_id': relatedId,
  };

  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    String? createdAt,
    String? relatedId,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      relatedId: relatedId ?? this.relatedId,
    );
  }

  /// Get type display icon
  String getTypeIcon() {
    switch (type.toLowerCase()) {
      case 'access_request':
        return '📨';
      case 'access_approved':
        return '✅';
      case 'system':
        return 'ℹ️';
      default:
        return '🔔';
    }
  }

  @override
  String toString() => 'Notification(id: $id, type: $type, isRead: $isRead)';
}
