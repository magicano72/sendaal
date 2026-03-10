import '../error/exceptions.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserRepository {
  final UserService userService;

  UserRepository(this.userService);

  Future<User> getUserProfile(String userId) async {
    try {
      final response = await userService.getUserProfile(userId);
      return User.fromJson(response);
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch user profile: ${e.toString()}',
      );
    }
  }

  Future<List<User>> searchUsers(String query) async {
    try {
      final responses = await userService.searchUsers(query);
      return responses.map((data) => User.fromJson(data)).toList();
    } catch (e) {
      throw ApiException(message: 'Failed to search users: ${e.toString()}');
    }
  }
}
