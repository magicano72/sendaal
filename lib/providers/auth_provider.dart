import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/user_model.dart';
import '../services/auth_service.dart';

/// Holds the currently authenticated user (null = logged out)
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) => AuthState(
    user: clearUser ? null : user ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
  );
}

/// Provides the AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Notifier that manages auth state throughout the app
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  Future<bool> login(String email, String password) async {
    print('[AuthNotifier] Starting login for: $email');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      print('[AuthNotifier] Login response: $response');
      // TODO: fetch current user after login
      state = state.copyWith(isLoading: false);
      print('[AuthNotifier] Login completed successfully');
      return true;
    } catch (e) {
      print('[AuthNotifier] Login error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('ApiException', '').trim(),
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String username) async {
    print(
      '[AuthNotifier] Starting registration for: $email, username: $username',
    );
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.register(
        email: email,
        password: password,
        username: username,
      );
      print('[AuthNotifier] Registration completed successfully');
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      print('[AuthNotifier] Register error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('ApiException', '').trim(),
      );
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
  return AuthNotifier(ref.read(authServiceProvider));
});
