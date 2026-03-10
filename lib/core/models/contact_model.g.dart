// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Contact _$ContactFromJson(Map<String, dynamic> json) => Contact(
  id: json['id'] as String,
  userId: json['userId'] as String,
  contactName: json['contactName'] as String,
  contactPhone: json['contactPhone'] as String,
  matchedUserId: json['matchedUserId'] as String?,
);

Map<String, dynamic> _$ContactToJson(Contact instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'contactName': instance.contactName,
  'contactPhone': instance.contactPhone,
  'matchedUserId': instance.matchedUserId,
};
