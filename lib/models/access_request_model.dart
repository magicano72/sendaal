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
  final bool visibleForRequester;
  final bool visibleForReceiver;
  final bool isFavorite;

  const AccessRequest({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.rejectionCount = 0,
    this.visibleForRequester = true,
    this.visibleForReceiver = true,
    this.isFavorite = false,
  });

  factory AccessRequest.fromJson(Map<String, dynamic> json) => AccessRequest(
        id: json['id']?.toString() ?? '',
        requesterId: _extractId(json['requester']) ??
            json['requesterId']?.toString() ??
            '',
        receiverId: _extractId(json['receiver']) ??
            json['receiverId']?.toString() ??
            '',
        status: AccessStatus.fromString(json['status']?.toString() ?? 'pending'),
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        rejectionCount:
            int.tryParse(json['rejection_count']?.toString() ?? '0') ?? 0,
        visibleForRequester:
            json['visible_for_requester'] != false &&
            json['visibleForRequester'] != false,
        visibleForReceiver:
            json['visible_for_receiver'] != false &&
            json['visibleForReceiver'] != false,
        isFavorite: json['is_favorite'] == true ||
            json['isFavorite'] == true,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'requester': requesterId,
    'receiver': receiverId,
    'status': status.name,
    'created_at': createdAt.toIso8601String().split('T')[0],
    'visible_for_requester': visibleForRequester,
    'visible_for_receiver': visibleForReceiver,
    'is_favorite': isFavorite,
  };

  bool get canHide =>
      status == AccessStatus.approved || status == AccessStatus.rejected;

  AccessRequest copyWith({
    String? id,
    String? requesterId,
    String? receiverId,
    AccessStatus? status,
    DateTime? createdAt,
    int? rejectionCount,
    bool? visibleForRequester,
    bool? visibleForReceiver,
    bool? isFavorite,
  }) => AccessRequest(
    id: id ?? this.id,
    requesterId: requesterId ?? this.requesterId,
    receiverId: receiverId ?? this.receiverId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    rejectionCount: rejectionCount ?? this.rejectionCount,
    visibleForRequester: visibleForRequester ?? this.visibleForRequester,
    visibleForReceiver: visibleForReceiver ?? this.visibleForReceiver,
    isFavorite: isFavorite ?? this.isFavorite,
  );

  static String? _extractId(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value['id']?.toString();
    }
    if (value != null) return value.toString();
    return null;
  }
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
