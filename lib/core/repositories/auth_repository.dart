import '../error/exceptions.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService authService;

  AuthRepository(this.authService);

  Future<User> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await authService.register(
        email: email,
        password: password,
        username: username,
      );
      return User.fromJson(response);
    } catch (e) {
      throw AuthException('Registration failed: ${e.toString()}');
    }
  }

  Future<User> login({required String email, required String password}) async {
    try {
      final response = await authService.login(
        email: email,
        password: password,
      );
      return User.fromJson(response);
    } catch (e) {
      throw AuthException('Login failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await authService.logout();
    } catch (e) {
      throw AuthException('Logout failed: ${e.toString()}');
    }
  }
}
