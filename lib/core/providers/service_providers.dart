import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sendaal/core/services/user_service.dart';

import '../../services/access_service.dart';
import '../repositories/index.dart';
import '../services/index.dart' hide AccessService;

/// Provides the API Client instance
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance;
});

/// Provides Auth Service
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

/// Provides User Service
final userServiceProvider = Provider<UserService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserService(apiClient);
});

/// Provides Account Service
final accountServiceProvider = Provider<AccountService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AccountService(apiClient);
});

/// Provides Access Service
final accessServiceProvider = Provider<AccessService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AccessService(apiClient: apiClient);
});

/// Provides Notification Service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationService(apiClient);
});

// ============ REPOSITORY PROVIDERS ============

/// Provides Auth Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthRepository(authService);
});

/// Provides User Repository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final userService = ref.watch(userServiceProvider);
  return UserRepository(userService);
});

/// Provides Account Repository
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final accountService = ref.watch(accountServiceProvider);
  return AccountRepository(accountService);
});

/// Provides Access Request Repository
final accessRequestRepositoryProvider = Provider<AccessRequestRepository>((
  ref,
) {
  final accessService = ref.watch(accessServiceProvider);
  return AccessRequestRepository(accessService);
});

/// Provides Notification Repository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationRepository(notificationService);
});
