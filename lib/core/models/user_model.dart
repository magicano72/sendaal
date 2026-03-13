import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  /// Returns a fully-qualified asset URL, or null if no avatar is set.
  ///
  /// Handles three cases:
  ///   • null / empty string  → null (show initials)
  ///   • already a full URL   → returned as-is
  ///   • bare UUID            → BASE_URL/assets/<uuid>
  String? get avatarUrl {
    final raw = avatar;
    if (raw == null || raw.trim().isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = dotenv.env['BASE_URL'] ?? '';
    return '$base/assets/$raw';
  }

  /// 1–2 uppercase initials derived from displayName.
  ///   "Ahmed Faris" → "AF"
  ///   "Omar"        → "O"
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

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
