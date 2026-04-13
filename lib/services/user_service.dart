import 'dart:io';

import '../core/models/user_model.dart';
import 'api_client.dart';
import 'endpoint.dart';

/// Handles user profile and search operations
class UserService {
  final ApiClient _api;

  UserService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.instance;

  /// Normalize phone numbers to E.164-ish format with a default country code.
  /// - strips spaces/dashes/parentheses/other symbols
  /// - if already starts with '+' -> returned as-is (after cleanup)
  /// - if starts with '0' -> replace leading 0 with [defaultCountryCode]
  /// - else -> prepend [defaultCountryCode]
  static String normalizePhone(
    String phone, {
    String defaultCountryCode = '+20',
  }) {
    var cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return '';
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('0')) {
      return '$defaultCountryCode${cleaned.substring(1)}';
    }
    return '$defaultCountryCode$cleaned';
  }

  /// Get a user's profile by ID
  Future<User> getUserById(String id) async {
    final response = await _api.get(Endpoints.userById(id));
    final data = response['data'] as Map<String, dynamic>;
    return User.fromJson(data);
  }

  /// Search users by username (partial match via Directus filter)
  Future<List<User>> searchByUsername(String query) async {
    final trimmed = query.trim();
    // Don't send query if empty
    if (trimmed.isEmpty) return [];

    final response = await _api.get(
      Endpoints.users,
      queryParams: {'filter[username][_contains]': trimmed},
    );
    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Search users by phone number (partial match)
  Future<List<User>> searchByPhoneNumber(String phoneNumber) async {
    final normalized = normalizePhone(phoneNumber);
    // Don't send query if normalization resulted in empty string
    if (normalized.isEmpty) return [];

    // Use _contains for partial phone matching instead of exact match
    final response = await _api.get(
      Endpoints.users,
      queryParams: {'filter[phone_number][_contains]': normalized},
    );
    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Find a user by an exact phone match.
  Future<User?> findByPhoneNumber(String phoneNumber) async {
    final normalized = normalizePhone(phoneNumber);
    final response = await _api.get(
      Endpoints.users,
      queryParams: {'filter[phone_number][_eq]': normalized, 'limit': '1'},
    );
    final list = response['data'] as List<dynamic>? ?? [];
    if (list.isEmpty) return null;
    return User.fromJson(list.first as Map<String, dynamic>);
  }

  /// Batch lookup by phone numbers, returned as map phone -> User.
  Future<Map<String, User>> findUsersByPhoneNumbers(
    List<String> phoneNumbers,
  ) async {
    if (phoneNumbers.isEmpty) return {};
    final normalized = phoneNumbers
        .map(normalizePhone)
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();

    final response = await _api.get(
      Endpoints.users,
      queryParams: {
        'filter[phone_number][_in]': normalized.join(','),
        'limit': normalized.length.toString(),
      },
    );

    final list = response['data'] as List<dynamic>? ?? [];
    final map = <String, User>{};
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final user = User.fromJson(item);
      final phone = normalizePhone(user.phoneNumber ?? '');
      if (phone.isNotEmpty) map[phone] = user;
    }
    return map;
  }

  /// Check uniqueness of email/username/phone using a single public query.
  Future<UserAvailability> checkAvailability({
    required String email,
    required String username,
    required String phoneNumber,
  }) async {
    final normalizedPhone = normalizePhone(phoneNumber);
    final response = await _api.getPublic(
      Endpoints.users,
      queryParams: {
        'fields': 'email,phone_number,username',
        'limit': '3',
        'filter[_or][0][email][_eq]': email.trim().toLowerCase(),
        'filter[_or][1][phone_number][_eq]': normalizedPhone,
        'filter[_or][2][username][_eq]': username.trim(),
      },
    );

    final list = response['data'] as List<dynamic>? ?? [];
    var emailTaken = false;
    var phoneTaken = false;
    var usernameTaken = false;

    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final user = item;
      final uEmail = (user['email'] ?? '').toString().toLowerCase();
      final uPhone = normalizePhone(user['phone_number']?.toString() ?? '');
      final uUsername = (user['username'] ?? '').toString();

      if (uEmail == email.trim().toLowerCase()) emailTaken = true;
      if (uPhone.isNotEmpty && uPhone == normalizedPhone) phoneTaken = true;
      if (uUsername == username.trim()) usernameTaken = true;
    }

    return UserAvailability(
      emailTaken: emailTaken,
      phoneTaken: phoneTaken,
      usernameTaken: usernameTaken,
    );
  }

  /// Get current logged-in user profile
  Future<User> getCurrentUser() async {
    final response = await _api.get(Endpoints.currentUser);
    final data = response['data'] as Map<String, dynamic>;
    return User.fromJson(data);
  }

  /// Update user avatar/profile image (by ID)
  Future<User> updateAvatar(String userId, String avatarUrl) async {
    final response = await _api.patch(
      Endpoints.userById(userId),
      body: {'avatar': avatarUrl},
    );
    final data = response['data'] as Map<String, dynamic>;
    return User.fromJson(data);
  }

  /// Upload image file to Directus and update user avatar
  /// Returns updated user with new avatar URL
  Future<User> uploadAndUpdateAvatar({
    required String userId,
    required String filePath,
  }) async {
    try {
      // Upload file to Directus files endpoint using multipart
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final uploadResponse = await _api.postMultipart(
        '/files',
        fields: {},
        files: {'file': filePath},
      );

      // Extract file ID from response
      final fileId = uploadResponse['data']?['id'];
      if (fileId == null) {
        throw Exception('No file ID returned from upload');
      }

      print('[UserService] File uploaded successfully. ID: $fileId');

      // Update user with file reference
      final updateResponse = await _api.patch(
        Endpoints.userById(userId),
        body: {'avatar': fileId},
      );

      final data = updateResponse['data'] as Map<String, dynamic>;
      return User.fromJson(data);
    } catch (e) {
      print('[UserService] Error uploading avatar: $e');
      rethrow;
    }
  }

  String _normalizePhone(String raw) => normalizePhone(raw);
}

class UserAvailability {
  final bool emailTaken;
  final bool phoneTaken;
  final bool usernameTaken;

  const UserAvailability({
    required this.emailTaken,
    required this.phoneTaken,
    required this.usernameTaken,
  });

  bool get isAllFree => !emailTaken && !phoneTaken && !usernameTaken;
}
