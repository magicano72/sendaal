import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../services/auth_session_service.dart';

/// Initialization result for splash screen
class InitializationResult {
  final String nextRoute;
  final bool isAuthenticated;
  final bool hasPinSetup;
  final String? displayName;
  final bool showBiometricButton;

  const InitializationResult({
    required this.nextRoute,
    required this.isAuthenticated,
    required this.hasPinSetup,
    this.displayName,
    this.showBiometricButton = false,
  });
}

/// Splash screen that handles ALL app initialization
///
/// Responsibilities:
/// 1. Display splash image while initializing
/// 2. Check authentication state (tokens, PIN setup)
/// 3. Load user display name and biometric availability
/// 4. Bootstrap auth provider if needed
/// 5. Route to appropriate screen based on auth status
///
/// Flow:
/// - If authenticated + PIN setup → PIN login screen (with data pre-loaded)
/// - If authenticated + no PIN → PIN setup screen
/// - If not authenticated → Login screen
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final AuthSessionService _authService = AuthSessionService.instance;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize app completely - all checks and bootstrap
  ///
  /// This method:
  /// 1. Determines auth route (pinLogin/pinSetup/login)
  /// 2. If pinLogin: loads display name and biometric settings
  /// 3. If login: bootstraps auth provider
  /// 4. Navigates to appropriate screen with no further loading
  Future<void> _initializeApp() async {
    try {
      final result = await _performFullInitialization();
      _navigateToNextScreen(result);
    } catch (e) {
      debugPrint('[SplashScreen] Initialization error: $e');
      _navigateToNextScreen(
        const InitializationResult(
          nextRoute: AppRoutes.login,
          isAuthenticated: false,
          hasPinSetup: false,
        ),
      );
    }
  }

  /// Perform complete initialization based on auth state
  Future<InitializationResult> _performFullInitialization() async {
    final refreshToken = await _authService.secureStorage.read(
      key: kRefreshToken,
    );
    final pinHash = await _authService.secureStorage.read(key: kPinHash);

    // User NOT authenticated - just route to login, no bootstrap needed yet
    if (refreshToken == null) {
      return const InitializationResult(
        nextRoute: AppRoutes.login,
        isAuthenticated: false,
        hasPinSetup: false,
      );
    }

    // User authenticated but no PIN yet
    if (pinHash == null) {
      return const InitializationResult(
        nextRoute: AppRoutes.pinSetup,
        isAuthenticated: true,
        hasPinSetup: false,
      );
    }

    // User fully authenticated with PIN - load all data needed for PIN login screen
    final displayName = await _authService.readStoredDisplayName();
    final showBiometric =
        await _authService.isBiometricEnabled() &&
        await _authService.canUseBiometric();

    return InitializationResult(
      nextRoute: AppRoutes.pinLogin,
      isAuthenticated: true,
      hasPinSetup: true,
      displayName: displayName,
      showBiometricButton: showBiometric,
    );
  }

  /// Navigate to the next screen based on initialization result
  void _navigateToNextScreen(InitializationResult result) {
    if (!mounted) return;

    // Store initialization data in provider for screens to use
    ref.read(splashInitializationProvider.notifier).state = result;

    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed(result.nextRoute, arguments: result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fullscreen background image while all initialization happens silently
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash-screen.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

/// Provider to store splash initialization data for screens to access
final splashInitializationProvider = StateProvider<InitializationResult?>(
  (ref) => null,
);
