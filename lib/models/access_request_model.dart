import '../utils/date_utils.dart';

/// Status of an access request
///
/// Enum names stay camelCase for readability while [apiValue] matches the
/// Directus values we send/receive (snake_case).
enum AccessStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  cancelled('cancelled'),
  revoked('revoked'),
  revokedByRequester('revoked_by_requester'),
  revokedByReceiver('revoked_by_receiver');

  final String apiValue;
  const AccessStatus(this.apiValue);

  static AccessStatus fromString(String value) =>
      AccessStatus.values.firstWhere(
        (e) => e.apiValue == value || e.name == value,
        orElse: () => AccessStatus.pending,
      );
}

class AccessRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String receiverId;
  final AccessStatus status;
  final DateTime createdAt;
  final int rejectionCount;
  final bool visibleForRequester;
  final bool visibleForReceiver;
  final bool isFavorite;
  final String requestAccessType; // "full" | "custom"
  final String? approvedAccessType; // "full" | "custom" | null
  final String? revokedByUserId;

  const AccessRequest({
    required this.id,
    required this.requesterId,
    this.requesterName = '',
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.rejectionCount = 0,
    this.visibleForRequester = true,
    this.visibleForReceiver = true,
    this.isFavorite = false,
    this.requestAccessType = 'full',
    this.approvedAccessType,
    this.revokedByUserId,
  });

  factory AccessRequest.fromJson(Map<String, dynamic> json) => AccessRequest(
    id: json['id']?.toString() ?? '',
    requesterId:
        _extractId(json['requester']) ?? json['requesterId']?.toString() ?? '',
    requesterName: _extractName(
      json['requester'],
      explicitName:
          json['requester_name']?.toString() ??
          json['requesterName']?.toString(),
    ),
    receiverId:
        _extractId(json['receiver']) ?? json['receiverId']?.toString() ?? '',
    status: AccessStatus.fromString(json['status']?.toString() ?? 'pending'),
    createdAt: parseDirectusDateOrNow(
      json['created_at']?.toString() ?? json['createdAt']?.toString(),
    ),
    rejectionCount:
        int.tryParse(json['rejection_count']?.toString() ?? '0') ?? 0,
    visibleForRequester:
        json['visible_for_requester'] != false &&
        json['visibleForRequester'] != false,
    visibleForReceiver:
        json['visible_for_receiver'] != false &&
        json['visibleForReceiver'] != false,
    isFavorite: json['is_favorite'] == true || json['isFavorite'] == true,
    requestAccessType:
        (json['request_access_type'] ?? json['requestAccessType'])
            ?.toString() ??
        'full',
    approvedAccessType:
        (json['approved_access_type'] ?? json['approvedAccessType'])
            ?.toString(),
    revokedByUserId:
        _extractId(json['revoked_by']) ?? json['revokedBy']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'requester': requesterId,
    'requester_name': requesterName,
    'receiver': receiverId,
    'status': status.apiValue,
    'created_at': createdAt.toIso8601String().split('T')[0],
    'visible_for_requester': visibleForRequester,
    'visible_for_receiver': visibleForReceiver,
    'is_favorite': isFavorite,
    'request_access_type': requestAccessType,
    'approved_access_type': approvedAccessType,
    if (revokedByUserId != null) 'revoked_by': revokedByUserId,
  };

  bool get canHide => status != AccessStatus.pending;

  AccessRequest copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? receiverId,
    AccessStatus? status,
    DateTime? createdAt,
    int? rejectionCount,
    bool? visibleForRequester,
    bool? visibleForReceiver,
    bool? isFavorite,
    String? requestAccessType,
    String? approvedAccessType,
    String? revokedByUserId,
  }) => AccessRequest(
    id: id ?? this.id,
    requesterId: requesterId ?? this.requesterId,
    requesterName: requesterName ?? this.requesterName,
    receiverId: receiverId ?? this.receiverId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    rejectionCount: rejectionCount ?? this.rejectionCount,
    visibleForRequester: visibleForRequester ?? this.visibleForRequester,
    visibleForReceiver: visibleForReceiver ?? this.visibleForReceiver,
    isFavorite: isFavorite ?? this.isFavorite,
    requestAccessType: requestAccessType ?? this.requestAccessType,
    approvedAccessType: approvedAccessType ?? this.approvedAccessType,
    revokedByUserId: revokedByUserId ?? this.revokedByUserId,
  );

  /// True when either side has revoked access.
  bool get isRevoked =>
      status == AccessStatus.revoked ||
      status == AccessStatus.revokedByRequester ||
      status == AccessStatus.revokedByReceiver;

  /// Returns the user id that performed the revoke, if known.
  String? get revokerId {
    if (revokedByUserId != null) return revokedByUserId;
    if (status == AccessStatus.revokedByRequester) return requesterId;
    if (status == AccessStatus.revokedByReceiver) return receiverId;
    return null;
  }

  static String? _extractId(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value['id']?.toString();
    }
    if (value != null) return value.toString();
    return null;
  }

  static String _extractName(dynamic value, {String? explicitName}) {
    final trimmedExplicit = explicitName?.trim();
    if (trimmedExplicit != null && trimmedExplicit.isNotEmpty) {
      return trimmedExplicit;
    }

    if (value is Map<String, dynamic>) {
      final firstName = value['first_name']?.toString().trim();
      if (firstName != null && firstName.isNotEmpty) {
        return firstName;
      }

      final displayName = value['displayName']?.toString().trim();
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }

      final username = value['username']?.toString().trim();
      if (username != null && username.isNotEmpty) {
        return username;
      }
    }

    return '';
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

/// Backwards alias to align with API naming in docs.
typedef AccessRequestStatus = AccessStatus;
