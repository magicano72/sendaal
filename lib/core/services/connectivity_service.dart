import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to check internet connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final _connectivity = Connectivity();

  /// Check if device is currently connected to internet
  /// Returns true if connected, false if not
  /// Falls back to true if plugin is not available (assumes connected)
  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      print('[ConnectivityService] Connectivity check result: $result');

      // Check if any connection is available
      if (result.isEmpty) {
        return false;
      }

      // If connected to wifi or mobile, it's connected
      return result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.ethernet);
    } catch (e) {
      print('[ConnectivityService] Error checking connectivity: $e');
      // If plugin is not available or error occurs, assume connected
      // This prevents false negatives when plugin isn't properly initialized
      return true;
    }
  }
}
