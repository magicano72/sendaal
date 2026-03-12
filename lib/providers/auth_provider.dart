import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/exceptions.dart';
import '../core/models/user_model.dart';
import '../core/services/auth_service.dart';
import '../core/services/directus_error_parser.dart';
import '../services/api_client.dart' hide ApiException;
import '../services/user_service.dart';

/// Holds the currently authenticated user (null = logged out)
class AuthState {
  final User? user;
  final bool isLoading; // Deprecated: kept for backward compatibility
  final bool isLoginLoading;
  final bool isRegisterLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isLoginLoading = false,
    this.isRegisterLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isLoginLoading,
    bool? isRegisterLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) => AuthState(
    user: clearUser ? null : user ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    isLoginLoading: isLoginLoading ?? this.isLoginLoading,
    isRegisterLoading: isRegisterLoading ?? this.isRegisterLoading,
    error: clearError ? null : error ?? this.error,
  );
}

/// Provides the AuthService singleton
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ApiClient.instance),
);

/// Provides the UserService singleton
final userServiceProvider = Provider<UserService>((ref) => UserService());

/// Notifier that manages auth state throughout the app
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final UserService _userService;

  AuthNotifier(this._authService, this._userService) : super(const AuthState());

  Future<bool> login(String email, String password) async {
    print('[AuthNotifier] Starting login for: $email');
    state = state.copyWith(isLoginLoading: true, clearError: true);
    try {
      // Set 30 second timeout for login request
      final response = await _authService
          .login(email: email, password: password)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Login request timed out. Please try again.');
            },
          );
      print('[AuthNotifier] Login response: $response');

      // Fetch current user after successful login
      try {
        final user = await _userService.getCurrentUser().timeout(
          const Duration(seconds: 15),
        );
        state = state.copyWith(isLoginLoading: false, user: user);
        print('[AuthNotifier] User fetched successfully: ${user.id}');
      } catch (e) {
        print('[AuthNotifier] Error fetching current user: $e');
        state = state.copyWith(isLoginLoading: false);
      }

      print('[AuthNotifier] Login completed successfully');
      return true;
    } catch (e) {
      print('[AuthNotifier] Login error: $e');
      String errorMessage = 'Email or password is incorrect.';
      if (e is ApiException) {
        errorMessage = DirectusErrorParser.getGeneralErrorMessage(e);
      } else if (e.toString().contains('timed out')) {
        errorMessage =
            'Request took too long. Please check your connection and try again.';
      }
      state = state.copyWith(isLoginLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String phone,
  }) async {
    print(
      '[AuthNotifier] Starting registration for: $email, username: $username',
    );
    state = state.copyWith(isRegisterLoading: true, clearError: true);
    try {
      // Set 30 second timeout for registration request
      await _authService
          .register(
            email: email,
            password: password,
            username: username,
            firstName: firstName,
            phone: phone,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Registration request timed out. Please try again.',
              );
            },
          );
      print('[AuthNotifier] Registration completed successfully');
      state = state.copyWith(isRegisterLoading: false);
      return true;
    } catch (e) {
      print('[AuthNotifier] Register error: $e');
      String errorMessage = 'Something went wrong. Please try again.';
      if (e is ApiException) {
        errorMessage = DirectusErrorParser.getGeneralErrorMessage(e);
      } else if (e.toString().contains('timed out')) {
        errorMessage =
            'Request took too long. Please check your connection and try again.';
      }
      state = state.copyWith(isRegisterLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> refreshTokenIfNeeded() async {
    print('[AuthNotifier] Checking if token refresh is needed');
    try {
      // Get the refresh token from ApiClient
      final apiClient = ApiClient.instance;

      // Check if token is expired or about to expire
      if (!apiClient.isTokenExpired) {
        print('[AuthNotifier] Token is still valid, no refresh needed');
        return true;
      }

      // Check if we have a refresh token
      if (apiClient.refreshToken == null) {
        print('[AuthNotifier] No refresh token available');
        return false;
      }

      print('[AuthNotifier] Token expired or about to expire, refreshing...');
      await _authService.refreshToken(apiClient.refreshToken!);
      print('[AuthNotifier] Token refresh completed successfully');
      return true;
    } catch (e) {
      print('[AuthNotifier] Token refresh failed: $e');
      // If refresh fails, logout the user
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    print('[AuthNotifier] Starting logout');
    try {
      await _authService.logout();
      print('[AuthNotifier] Logout service completed');
      state = const AuthState();
      print('[AuthNotifier] Auth state cleared, logout completed');
    } catch (e) {
      print('[AuthNotifier] Logout error (continuing anyway): $e');
      state = const AuthState();
    }
  }

  void setUser(User user) {
    state = state.copyWith(user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(userServiceProvider),
  );
});
