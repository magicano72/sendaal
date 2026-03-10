// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccessRequest _$AccessRequestFromJson(Map<String, dynamic> json) =>
    AccessRequest(
      id: json['id'] as String,
      requesterId: json['requesterId'] as String,
      receiverId: json['receiverId'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
      requesterName: json['requesterName'] as String?,
      requesterUsername: json['requesterUsername'] as String?,
    );

Map<String, dynamic> _$AccessRequestToJson(AccessRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'requesterId': instance.requesterId,
      'receiverId': instance.receiverId,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'requesterName': instance.requesterName,
      'requesterUsername': instance.requesterUsername,
    };
