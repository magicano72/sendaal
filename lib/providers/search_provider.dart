import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/notification_model.dart';
import '../core/models/user_model.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';

// ── User / Search ─────────────────────────────────────────────────────────────

final userServiceProvider = Provider<UserService>((ref) => UserService());

class SearchState {
  final List<User> results;
  final bool isLoading;
  final String? error;
  final String query;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  SearchState copyWith({
    List<User>? results,
    bool? isLoading,
    String? error,
    String? query,
    bool clearError = false,
    bool clearResults = false,
  }) => SearchState(
    results: clearResults ? [] : results ?? this.results,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    query: query ?? this.query,
  );
}

class SearchNotifier extends StateNotifier<SearchState> {
  final UserService _service;

  SearchNotifier(this._service) : super(const SearchState());

  /// Check if a query looks like it could be a phone number
  /// Returns true if there are phone-like characters (digits, +, -, spaces, parentheses)
  static bool _couldBePhoneNumber(String query) {
    // Count digits and phone characters
    final digits = query.replaceAll(RegExp(r'[^0-9+\-\s().]'), '');
    final digitCount = query.replaceAll(RegExp(r'[^0-9]'), '').length;

    // If has phone-like characters and at least 3 digits, could be a phone search
    // This covers patterns like: "123", "+1-234", "(123) 456", etc.
    return digits.isNotEmpty && digitCount >= 3;
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(clearResults: true, query: '');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, query: query);

    try {
      // Always search by username
      final usernameResults = await _service.searchByUsername(trimmed);

      // Only search by phone if query looks like a phone number
      final phoneResults = _couldBePhoneNumber(trimmed)
          ? await _service.searchByPhoneNumber(trimmed)
          : <User>[];

      // Merge results by ID to avoid duplicates
      final merged = <String, User>{};
      for (final user in usernameResults) {
        merged[user.id] = user;
      }
      for (final user in phoneResults) {
        merged[user.id] = user;
      }

      state = state.copyWith(isLoading: false, results: merged.values.toList());
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Search failed: ${e.toString()}',
      );
    }
  }

  void clear() => state = const SearchState();
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  return SearchNotifier(ref.read(userServiceProvider));
});

// ── Notifications ─────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

class NotificationsState {
  final List<Notification> notifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => n.isRead != true).length;
  bool get hasUnread => unreadCount > 0;

  NotificationsState copyWith({
    List<Notification>? notifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => NotificationsState(
    notifications: notifications ?? this.notifications,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
  );
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationService _service;
  final Set<String> _notifiedIds = {};

  NotificationsNotifier(this._service) : super(const NotificationsState());

  Future<void> loadNotifications(String userId) async {
    print(
      '[NotificationsNotifier] Starting loadNotifications for userId: $userId',
    );
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _service.getNotifications(userId);
      print('[NotificationsNotifier] Loaded ${list.length} notifications');
      // Trigger local push for any new unread notifications
      for (final n in list) {
        print(
          '[NotificationsNotifier] Notification: id=${n.id}, title=${n.title}, isRead=${n.isRead}',
        );
        if (n.isRead == false && !_notifiedIds.contains(n.id)) {
          _notifiedIds.add(n.id);
          await LocalNotificationService.showNotification(
            id: n.id,
            title: n.title,
            body: n.body,
            payload: n.id,
          );
        }
      }
      state = state.copyWith(isLoading: false, notifications: list);
      print(
        '[NotificationsNotifier] State updated, notifications count: ${state.notifications.length}',
      );
    } catch (e) {
      print('[NotificationsNotifier] Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications: $e',
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final updated = await _service.markAsRead(notificationId);
      state = state.copyWith(
        notifications: state.notifications
            .map((n) => n.id == notificationId ? updated : n)
            .toList(),
      );
    } catch (_) {}
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
      return NotificationsNotifier(ref.read(notificationServiceProvider));
    });
