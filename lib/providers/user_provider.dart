import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/user_model.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

/// Fetch a user's profile by ID using FutureProvider for caching
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  final userService = ref.read(userServiceProvider);
  return userService.getUserById(userId);
});
