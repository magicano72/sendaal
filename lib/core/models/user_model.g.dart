// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String,
  profileImage: json['profileImage'] as String?,
  phone: json['phone'] as String?,
  isVerified: json['isVerified'] as bool,
  email: json['email'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'displayName': instance.displayName,
  'profileImage': instance.profileImage,
  'phone': instance.phone,
  'isVerified': instance.isVerified,
  'email': instance.email,
};
