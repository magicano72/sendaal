/// User model
class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String? profileImage;
  final String? phone;
  final bool isVerified;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.profileImage,
    this.phone,
    this.isVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        displayName: json['display_name']?.toString() ??
            json['displayName']?.toString() ??
            json['first_name']?.toString() ??
            '',
        profileImage: json['avatar']?.toString() ?? json['profileImage']?.toString(),
        phone: json['phone']?.toString(),
        isVerified: json['is_verified'] == true || json['isVerified'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'profileImage': profileImage,
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
  }) =>
      UserModel(
        id: id ?? this.id,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        profileImage: profileImage ?? this.profileImage,
        phone: phone ?? this.phone,
        isVerified: isVerified ?? this.isVerified,
      );
}
