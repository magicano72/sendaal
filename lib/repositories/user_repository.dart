import '../core/models/user_model.dart';
import '../services/user_service.dart';

/// Repository that wraps UserService.
/// Repositories are the single source of truth for domain data.
/// They can cache, merge, or adapt data from multiple services.
class UserRepository {
  final UserService _service;

  UserRepository({UserService? service}) : _service = service ?? UserService();

  Future<User> getUser(String id) => _service.getUserById(id);

  Future<List<User>> searchUsers(String query) {
    final isPhone = RegExp(r'^\+?[0-9\s\-]{7,}$').hasMatch(query.trim());
    return isPhone
        ? _service.searchByPhoneNumber(query)
        : _service.searchByUsername(query);
  }

  Future<User> updateAvatar(String userId, String avatarUrl) =>
      _service.updateAvatar(userId, avatarUrl);
}
