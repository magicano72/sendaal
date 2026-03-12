import 'dart:io';

import '../core/models/user_model.dart';
import 'api_client.dart';
import 'endpoint.dart';

/// Handles user profile and search operations
class UserService {
  final ApiClient _api;

  UserService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.instance;

  /// Get a user's profile by ID
  Future<User> getUserById(String id) async {
    final response = await _api.get(Endpoints.userById(id));
    final data = response['data'] as Map<String, dynamic>;
    return User.fromJson(data);
  }

  /// Search users by username (partial match via Directus filter)
  Future<List<User>> searchByUsername(String query) async {
    final response = await _api.get(
      Endpoints.users,
      queryParams: {'filter[username][_contains]': query},
    );
    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Search users by phone number
  Future<List<User>> searchByPhone(String phone) async {
    final response = await _api.get(
      Endpoints.users,
      queryParams: {'filter[phone][_contains]': phone},
    );
    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
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
}
