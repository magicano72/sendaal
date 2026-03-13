import 'package:flutter/foundation.dart';
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
  }) {
    // 🔍 DEBUG: log every User construction so we can see raw avatar value
    debugPrint('╔══ User() constructed ══════════════════════');
    debugPrint('║  id          : $id');
    debugPrint('║  displayName : $displayName');
    debugPrint('║  avatar(raw) : $avatar');
    debugPrint('╚════════════════════════════════════════════');
  }

  String? get avatarUrl {
    final raw = avatar;

    debugPrint('╔══ avatarUrl getter called ═════════════════');
    debugPrint('║  avatar(raw) : $raw');

    if (raw == null || raw.trim().isEmpty) {
      debugPrint('║  result      : null (empty/null raw)');
      debugPrint('╚════════════════════════════════════════════');
      return null;
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      debugPrint('║  result      : $raw (already full URL)');
      debugPrint('╚════════════════════════════════════════════');
      return raw;
    }

    // bare UUID — check dotenv
    final base = dotenv.env['BASE_URL'] ?? '';
    debugPrint('║  BASE_URL    : "$base"');

    if (base.isEmpty) {
      debugPrint('║  ⚠️  BASE_URL is EMPTY — dotenv not loaded yet!');
      debugPrint('╚════════════════════════════════════════════');
      // Return null → show initials instead of crashing with file:/// URI
      return null;
    }

    final url = '$base/assets/$raw';
    debugPrint('║  result      : $url');
    debugPrint('╚════════════════════════════════════════════');
    return url;
  }

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // 🔍 DEBUG: log raw JSON before deserialization
    debugPrint('╔══ User.fromJson() ═════════════════════════');
    debugPrint('║  raw json    : $json');
    debugPrint('╚════════════════════════════════════════════');
    return _$UserFromJson(json);
  }

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
