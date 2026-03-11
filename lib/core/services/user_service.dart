import '../../services/api_client.dart';

class UserService {
  final ApiClient apiClient;

  UserService(this.apiClient);

  /// Search users by username or phone (for contact list)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final result = await apiClient.get(
        '/users',
        queryParams: {'filter[username][_contains]': query, 'limit': '20'},
      );

      if (result['data'] is List) {
        return List<Map<String, dynamic>>.from(result['data']);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get user profile by ID
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final result = await apiClient.get('/users/$userId');
      return result['data'] ?? result;
    } catch (e) {
      rethrow;
    }
  }

  /// Get current logged-in user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final result = await apiClient.get('/users/me');
      return result['data'] ?? result;
    } catch (e) {
      rethrow;
    }
  }
}
