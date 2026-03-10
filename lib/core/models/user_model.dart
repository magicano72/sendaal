import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String username;
  final String displayName;
  final String? profileImage;
  final String? phone;
  final bool isVerified;
  final String? email;

  User({
    required this.id,
    required this.username,
    required this.displayName,
    this.profileImage,
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
    String? profileImage,
    String? phone,
    bool? isVerified,
    String? email,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profileImage: profileImage ?? this.profileImage,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      email: email ?? this.email,
    );
  }

  @override
  String toString() =>
      'User(id: $id, username: $username, displayName: $displayName, isVerified: $isVerified)';
}
