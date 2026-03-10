import 'package:json_annotation/json_annotation.dart';

part 'access_request_model.g.dart';

@JsonSerializable()
class AccessRequest {
  final String id;
  final String requesterId;
  final String receiverId;
  final String status; // pending, approved, rejected
  final String createdAt;
  final String? requesterName;
  final String? requesterUsername;

  AccessRequest({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.requesterName,
    this.requesterUsername,
  });

  factory AccessRequest.fromJson(Map<String, dynamic> json) =>
      _$AccessRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AccessRequestToJson(this);

  AccessRequest copyWith({
    String? id,
    String? requesterId,
    String? receiverId,
    String? status,
    String? createdAt,
    String? requesterName,
    String? requesterUsername,
  }) {
    return AccessRequest(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      requesterName: requesterName ?? this.requesterName,
      requesterUsername: requesterUsername ?? this.requesterUsername,
    );
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  @override
  String toString() =>
      'AccessRequest(id: $id, requester: $requesterId, status: $status)';
}
