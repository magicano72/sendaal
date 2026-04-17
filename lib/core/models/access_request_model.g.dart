// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccessRequest _$AccessRequestFromJson(Map<String, dynamic> json) =>
    AccessRequest(
      id: json['id'] as String,
      requesterId: json['requester'] as String,
      receiverId: json['receiver'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      requesterName: json['requesterName'] as String?,
      requesterUsername: json['requesterUsername'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      requestAccessType: json['request_access_type'] as String? ?? 'full',
      approvedAccessType: json['approved_access_type'] as String?,
    );

Map<String, dynamic> _$AccessRequestToJson(AccessRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'requester': instance.requesterId,
      'receiver': instance.receiverId,
      'status': instance.status,
      'created_at': instance.createdAt,
      'requesterName': instance.requesterName,
      'requesterUsername': instance.requesterUsername,
      'is_favorite': instance.isFavorite,
      'request_access_type': instance.requestAccessType,
      'approved_access_type': instance.approvedAccessType,
    };
