/// Status of an access request
enum AccessStatus {
  pending,
  approved,
  rejected;

  static AccessStatus fromString(String value) => AccessStatus.values
      .firstWhere((e) => e.name == value, orElse: () => AccessStatus.pending);
}

class AccessRequest {
  final String id;
  final String requesterId;
  final String receiverId;
  final AccessStatus status;
  final DateTime createdAt;
  final int rejectionCount;

  const AccessRequest({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.rejectionCount = 0,
  });

  factory AccessRequest.fromJson(Map<String, dynamic> json) => AccessRequest(
    id: json['id']?.toString() ?? '',
    requesterId:
        json['requester']?.toString() ?? json['requesterId']?.toString() ?? '',
    receiverId:
        json['receiver']?.toString() ?? json['receiverId']?.toString() ?? '',
    status: AccessStatus.fromString(json['status']?.toString() ?? 'pending'),
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
    rejectionCount:
        int.tryParse(json['rejection_count']?.toString() ?? '0') ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'requester': requesterId,
    'receiver': receiverId,
    'status': status.name,
    'created_at': createdAt.toIso8601String().split('T')[0],
  };
}

/// A contact in a user's address book
class Contact {
  final String id;
  final String userId;
  final String contactName;
  final String contactPhone;
  final String? matchedUserId;

  const Contact({
    required this.id,
    required this.userId,
    required this.contactName,
    required this.contactPhone,
    this.matchedUserId,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id']?.toString() ?? '',
    userId: json['user']?.toString() ?? json['userId']?.toString() ?? '',
    contactName:
        json['contact_name']?.toString() ??
        json['contactName']?.toString() ??
        '',
    contactPhone:
        json['contact_phone']?.toString() ??
        json['contactPhone']?.toString() ??
        '',
    matchedUserId:
        json['matched_user']?.toString() ?? json['matchedUserId']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user': userId,
    'contact_name': contactName,
    'contact_phone': contactPhone,
    'matched_user': matchedUserId,
  };
}
