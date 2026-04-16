import 'package:flutter/foundation.dart';

/// Manages app session inactivity and lock state.
///
/// This service tracks when the app goes to background/foreground and determines
/// if the app should be locked based on the inactivity threshold (3 minutes by default).
///
/// **Thread Safety**: Uses a simple lock pattern suitable for single-threaded Dart VM.
class SessionManager {
  SessionManager._internal();

  static final SessionManager instance = SessionManager._internal();

  /// Inactivity threshold in minutes (default: 3 minutes)
  static const int inactivityThresholdMinutes = 3;

  /// Tracks the last time the app was actively used (resumed)
  DateTime? _lastActiveTime;

  /// Tracks when the app went to background
  DateTime? _backupgroundTime;

  /// Whether app is currently locked due to inactivity
  bool _isAppLocked = false;

  /// Listeners for app lock state changes
  final ValueNotifier<bool> appLockStateNotifier = ValueNotifier<bool>(false);

  /// Initialize session tracking on app resume
  void markAppActive() {
    _lastActiveTime = DateTime.now();
    _isAppLocked = false;
    appLockStateNotifier.value = false;
    debugPrint('[SessionManager] App marked as active at $_lastActiveTime');
  }

  /// Save timestamp when app goes to background
  void markAppBackground() {
    _backupgroundTime = DateTime.now();
    debugPrint('[SessionManager] App went to background at $_backupgroundTime');
  }

  /// Determine if app should be locked based on inactivity
  ///
  /// Returns `true` if:
  /// - App was in background longer than the inactivity threshold
  ///
  /// Returns `false` if:
  /// - Less than threshold time has passed
  /// - OR this is the first time tracking (no background time recorded)
  bool shouldLockApp() {
    // First launch or app never went to background — don't lock
    if (_backupgroundTime == null) {
      debugPrint('[SessionManager] No background timestamp, app will not lock');
      return false;
    }

    // Calculate time spent in background (from when app paused until now)
    final now = DateTime.now();
    final inactivityDuration = now.difference(_backupgroundTime!);
    final thresholdDuration = Duration(minutes: inactivityThresholdMinutes);

    final shouldLock = inactivityDuration > thresholdDuration;

    debugPrint(
      '[SessionManager] Inactivity check: '
      'inactivity=${inactivityDuration.inMinutes}m, '
      'threshold=${thresholdDuration.inMinutes}m, '
      'shouldLock=$shouldLock',
    );

    if (shouldLock) {
      _isAppLocked = true;
      appLockStateNotifier.value = true;
    }

    return shouldLock;
  }

  /// Check if app is currently locked without triggering lock logic
  bool get isAppLocked => _isAppLocked;

  /// Reset session state (e.g., after successful PIN verification)
  void resetLockState() {
    _isAppLocked = false;
    appLockStateNotifier.value = false;
    _lastActiveTime = DateTime.now();
    _backupgroundTime = null;
    debugPrint('[SessionManager] Lock state reset');
  }

  /// Get time remaining until lock (in seconds)
  /// Returns null if app is not in background or threshold is not applicable
  int? getSecondsUntilLock() {
    if (_backupgroundTime == null) {
      return null;
    }

    final now = DateTime.now();
    final inactivityDuration = now.difference(_backupgroundTime!);
    final thresholdDuration = Duration(minutes: inactivityThresholdMinutes);
    final remaining =
        thresholdDuration.inSeconds - inactivityDuration.inSeconds;

    return remaining > 0 ? remaining : 0;
  }

  /// Dispose notifiers when session manager is no longer needed
  void dispose() {
    appLockStateNotifier.dispose();
  }
}
