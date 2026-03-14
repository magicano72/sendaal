import '../../services/api_client.dart';

class AuthService {
  final ApiClient apiClient;

  AuthService(this.apiClient);

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String phone,
  }) async {
    print(
      '[AuthService] Attempting to register with email: $email, username: $username',
    );
    try {
      final response = await apiClient.post(
        '/users',
        body: {
          'email': email,
          'password': password,
          'username': username,
          'first_name': firstName,
          'phone': phone,
        },
      );
      print('[AuthService] Registration successful: $response');
      return response is Map<String, dynamic> ? response : {};
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
        apiClient.setToken(
          response['data']['access_token'],
          refreshToken: response['data']['refresh_token'],
          expiresIn: response['data']['expires'],
        );
      }
      return response;
    } catch (e) {
      print('[AuthService] Login error: $e');
      rethrow;
    }
  }

  /// Refresh access token using refresh token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    print('[AuthService] Attempting to refresh token');
    try {
      final response = await apiClient.post(
        '/auth/refresh',
        body: {'refresh_token': refreshToken},
      );
      print('[AuthService] Token refresh successful');
      if (response['data'] != null &&
          response['data']['access_token'] != null) {
        print('[AuthService] Setting new token from refresh response');
        apiClient.setToken(
          response['data']['access_token'],
          refreshToken: response['data']['refresh_token'],
          expiresIn: response['data']['expires'],
        );
      }
      return response;
    } catch (e) {
      print('[AuthService] Token refresh error: $e');
      rethrow;
    }
  }

  /// Logout user - clear token and invalidate refresh token
  Future<void> logout() async {
    print('[AuthService] Attempting to logout');
    try {
      // Try to call logout endpoint with refresh token
      try {
        final refreshToken = apiClient.refreshToken;
        if (refreshToken != null) {
          await apiClient.post(
            '/auth/logout',
            body: {'refresh_token': refreshToken},
          );
          print('[AuthService] Logout API call successful');
        } else {
          print('[AuthService] No refresh token available for logout');
        }
      } catch (e) {
        print('[AuthService] Logout API call failed: $e');
        // Continue with clearing token anyway
      }
    } finally {
      print('[AuthService] Clearing auth token');
      apiClient.clearToken();
    }
  }
}
