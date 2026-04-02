// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  username: json['username'] as String? ?? '',
  displayName: json['displayName'] as String? ?? '',
  firstName: json['first_name'] as String?,
  avatar: json['avatar'] as String?,
  phoneNumber: json['phone_number'] as String?,
  isVerified: json['isVerified'] as bool? ?? false,
  email: json['email'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'displayName': instance.displayName,
  'first_name': instance.firstName,
  'avatar': instance.avatar,
  'phone_number': instance.phoneNumber,
  'isVerified': instance.isVerified,
  'email': instance.email,
};
