/// User model
class UserModel {
  final String id;
  final String username;
  final String name;
  final String? avatar;
  final String? phone;
  final bool isVerified;

  const UserModel({
    required this.id,
    required this.username,
    required this.name,
    this.avatar,
    this.phone,
    this.isVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id']?.toString() ?? '',
    username: json['username']?.toString() ?? '',
    name: json['first_name']?.toString() ?? 'User',
    avatar: json['avatar']?.toString() ?? json['profileImage']?.toString(),
    phone: json['phone']?.toString(),
    isVerified: json['is_verified'] == true || json['isVerified'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'first_name': name,
    'avatar': avatar,
    'phone': phone,
    'is_verified': isVerified,
  };

  UserModel copyWith({
    String? id,
    String? username,
    String? displayName,
    String? profileImage,
    String? phone,
    bool? isVerified,
  }) => UserModel(
    id: id ?? this.id,
    username: username ?? this.username,
    name: displayName ?? this.name,
    avatar: profileImage ?? this.avatar,
    phone: phone ?? this.phone,
    isVerified: isVerified ?? this.isVerified,
  );
}
