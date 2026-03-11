import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String username;
  @JsonKey(defaultValue: '')
  final String displayName;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'avatar')
  final String? avatar;
  @JsonKey(name: 'phone')
  final String? phone;
  @JsonKey(defaultValue: false)
  final bool isVerified;
  @JsonKey(name: 'email')
  final String? email;

  User({
    required this.id,
    required this.username,
    required this.displayName,
    this.firstName,
    this.avatar,
    this.phone,
    required this.isVerified,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? username,
    String? displayName,
    String? firstName,
    String? avatar,
    String? phone,
    bool? isVerified,
    String? email,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      email: email ?? this.email,
    );
  }

  @override
  String toString() =>
      'User(id: $id, username: $username, displayName: $displayName, isVerified: $isVerified)';
}
