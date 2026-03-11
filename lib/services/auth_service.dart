import 'api_client.dart';
import 'endpoint.dart';

/// Handles all authentication operations
class AuthService {
  final ApiClient _api;

  AuthService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.instance;

  /// Log in with email and password. Sets the Bearer token on success.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      Endpoints.login,
      body: {'email': email, 'password': password},
    );

    final data = response['data'] as Map<String, dynamic>;
    final token = data['access_token']?.toString() ?? '';
    _api.setToken(token);

    return {'token': token, 'refreshToken': data['refresh_token']};
  }

  /// Register a new user account
  Future<void> register({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String phone,
  }) async {
    await _api.post(
      Endpoints.register,
      body: {
        'email': email,
        'password': password,
        'username': username,
        'first_name': firstName,
        'phone': phone,
      },
    );
  }

  /// Log out and clear the stored token
  Future<void> logout() async {
    try {
      await _api.post(Endpoints.logout);
    } finally {
      _api.clearToken();
    }
  }
}
