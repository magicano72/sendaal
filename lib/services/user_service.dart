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
}
