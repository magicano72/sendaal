import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/session_manager.dart';

/// Provides the SessionManager singleton instance
///
/// Usage:
/// ```dart
/// final sessionManager = ref.watch(sessionManagerProvider);
/// sessionManager.markAppActive();
/// ```
final sessionManagerProvider = Provider((ref) {
  return SessionManager.instance;
});

/// Provides a listenable of app lock state changes
///
/// Use this in a Consumer widget to rebuild when lock state changes
///
/// Usage:
/// ```dart
/// final lockNotifier = ref.watch(appLockStateListenableProvider);
/// lockNotifier.listen((isLocked) {
///   if (isLocked) {
///     // Show PIN screen
///   }
/// });
/// ```
final appLockStateListenableProvider = Provider((ref) {
  final sessionManager = ref.watch(sessionManagerProvider);
  return sessionManager.appLockStateNotifier;
});
