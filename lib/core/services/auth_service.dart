import 'api_client.dart';

class AuthService {
  final ApiClient apiClient;

  AuthService(this.apiClient);

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username,
  }) async {
    print(
      '[AuthService] Attempting to register with email: $email, username: $username',
    );
    try {
      final response = await apiClient.post(
        '/users',
        body: {'email': email, 'password': password, 'username': username},
      );
      print('[AuthService] Registration successful: $response');
      return response;
    } catch (e) {
      print('[AuthService] Registration error: $e');
      rethrow;
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    print('[AuthService] Attempting to login with email: $email');
    try {
      final response = await apiClient.post(
        '/auth/login',
        body: {'email': email, 'password': password},
      );
      print('[AuthService] Login successful');
      if (response['data'] != null &&
          response['data']['access_token'] != null) {
        print('[AuthService] Setting token from response');
        apiClient.setToken(response['data']['access_token']);
      }
      return response;
    } catch (e) {
      print('[AuthService] Login error: $e');
      rethrow;
    }
  }

  /// Logout user - clear token without making API call (Directus refresh token issue)
  Future<void> logout() async {
    print('[AuthService] Attempting to logout');
    try {
      // Try to call logout endpoint, but don't fail if it does
      try {
        await apiClient.post('/auth/logout', body: {});
        print('[AuthService] Logout API call successful');
      } catch (e) {
        print('[AuthService] Logout API call failed (expected): $e');
        // Continue with clearing token anyway
      }
    } finally {
      print('[AuthService] Clearing auth token');
      apiClient.clearToken();
    }
  }
}
