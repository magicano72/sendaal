import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to check internet connectivity and broadcast changes globally.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// Public stream of online/offline status.
  /// Emits the initial connectivity state and keeps listening for changes.
  Stream<bool> get statusStream async* {
    yield await hasInternetConnection();
    yield* _connectivity.onConnectivityChanged.asyncMap((results) async {
      final isInterfaceUp = _isInterfaceConnected(results);
      if (!isInterfaceUp) return false;
      return _hasReachableHost();
    });
  }

  /// Check if device currently has internet access.
  /// Combines interface status with a lightweight DNS lookup for reliability.
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      print('[ConnectivityService] Connectivity check result: $results');

      if (!_isInterfaceConnected(results)) return false;

      return _hasReachableHost();
    } catch (e) {
      print('[ConnectivityService] Error checking connectivity: $e');
      // If plugin is not available or error occurs, assume connected
      // to avoid blocking the app with false negatives.
      return true;
    }
  }

  bool _isInterfaceConnected(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
  }

  Future<bool> _hasReachableHost() async {
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
