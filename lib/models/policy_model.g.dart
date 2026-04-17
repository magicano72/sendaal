// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'policy_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolicyModel _$PolicyModelFromJson(Map<String, dynamic> json) => PolicyModel(
  id: json['id'],
  title: json['title'] as String,
  content: json['content'] as String,
  type: json['type'] as String,
  status: json['status'] as String,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$PolicyModelToJson(PolicyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'type': instance.type,
      'status': instance.status,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

PoliciesResponse _$PoliciesResponseFromJson(Map<String, dynamic> json) =>
    PoliciesResponse(
      policies: (json['data'] as List<dynamic>)
          .map((e) => PolicyModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PoliciesResponseToJson(PoliciesResponse instance) =>
    <String, dynamic>{'data': instance.policies};
