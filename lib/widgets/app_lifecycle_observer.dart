import 'package:flutter/material.dart';

import '../core/router/app_router.dart';
import '../services/auth_session_service.dart';
import '../services/local_notification_service.dart';
import '../services/session_manager.dart';

/// Observes app lifecycle and enforces inactivity lock.
///
/// This widget:
/// 1. Monitors when app goes to background/foreground
/// 2. Tracks inactivity duration
/// 3. Forces PIN screen if inactivity exceeds threshold
/// 4. Prevents duplicate navigation attempts
///
/// Must be integrated into the root MaterialApp widget.
class AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  const AppLifecycleObserver({super.key, required this.child});

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  late final SessionManager _sessionManager;

  /// Prevents multiple lock navigation triggers
  bool _lockNavigationInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionManager = SessionManager.instance;

    // Initialize active time on first app launch
    _sessionManager.markAppActive();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App going to background
        _sessionManager.markAppBackground();
        debugPrint('[AppLifecycleObserver] App paused');

      case AppLifecycleState.inactive:
        // App entering inactive state (e.g., during route transitions)
        // Don't mark as background yet
        debugPrint('[AppLifecycleObserver] App inactive');

      case AppLifecycleState.resumed:
        // App coming to foreground
        debugPrint('[AppLifecycleObserver] App resumed');
        _handleAppResumed();

      case AppLifecycleState.detached:
        // App being terminated
        debugPrint('[AppLifecycleObserver] App detached');

      case AppLifecycleState.hidden:
        // App is hidden but still in memory (rare)
        debugPrint('[AppLifecycleObserver] App hidden');
    }
  }

  /// Handles app resume with inactivity lock check
  ///
  /// 1. Checks if app should be locked
  /// 2. If yes: navigates to PIN login with special flag
  /// 3. If no: resumes normally
  void _handleAppResumed() async {
    // Prevent multiple simultaneous lock navigation attempts
    if (_lockNavigationInProgress) {
      debugPrint(
        '[AppLifecycleObserver] Lock navigation already in progress, skipping',
      );
      return;
    }

    // Check if app should be locked
    final shouldLock = _sessionManager.shouldLockApp();

    if (!shouldLock) {
      // App in safe window, no lock needed
      _sessionManager.markAppActive();
      debugPrint('[AppLifecycleObserver] App resumed within safe window');
      return;
    }

    // App exceeded inactivity threshold, lock it
    debugPrint('[AppLifecycleObserver] App locked due to inactivity');
    await _navigateToPinLock();
  }

  /// Navigate to PIN lock screen safely
  ///
  /// Uses the app's navigatorKey to access Navigator reliably,
  /// prevents duplicate navigation, and preserves app state.
  Future<void> _navigateToPinLock() async {
    _lockNavigationInProgress = true;

    try {
      // Small delay to ensure navigation context is ready after app resume
      await Future.delayed(const Duration(milliseconds: 500));

      final navigator = LocalNotificationService.navigatorKey.currentState;
      if (navigator == null) {
        debugPrint('[AppLifecycleObserver] Navigator not available');
        return;
      }

      // Check if pages exist and if we're already on PIN login screen
      if (navigator.widget.pages.isNotEmpty) {
        final currentRoute = navigator.widget.pages.last.name;
        if (currentRoute == AppRoutes.pinLogin) {
          debugPrint(
            '[AppLifecycleObserver] Already on PIN login, skipping navigation',
          );
          _lockNavigationInProgress = false;
          return;
        }
      }

      // Verify user has PIN setup before forcing lock
      final pinHash = await AuthSessionService.instance.secureStorage.read(
        key: 'pin_hash',
      );
      if (pinHash == null) {
        debugPrint('[AppLifecycleObserver] PIN not setup, skipping lock');
        _lockNavigationInProgress = false;
        return;
      }

      // Push PIN screen without clearing navigation stack
      navigator.pushNamedAndRemoveUntil(AppRoutes.pinLogin, (route) {
        // Keep all previous routes in stack so back navigation works after unlock
        return true;
      }, arguments: {'isInactivityLock': true});

      debugPrint('[AppLifecycleObserver] Navigated to PIN lock screen');
    } catch (e) {
      debugPrint('[AppLifecycleObserver] Navigation error: $e');
    } finally {
      _lockNavigationInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
