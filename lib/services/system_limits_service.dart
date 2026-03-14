import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../core/constants/app_constants.dart';
import 'api_client.dart';
import 'endpoint.dart';

/// Fetches system-wide account limits and caches them in [AppConstants].
class SystemLimitsService {
  final ApiClient _apiClient;

  SystemLimitsService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Retrieve limits from the backend and convert them to a Map<String, double>.
  Future<Map<String, double>> fetchAccountTypeLimits() async {
    final response = await _apiClient.get(Endpoints.systemLimits);
    final data = response is Map ? response['data'] : null;
    return _extractLimitsFromData(data);
  }

  /// Load limits at app startup and persist them in memory with fallback asset.
  Future<Map<String, double>> loadAndCache() async {
    try {
      final limits = await fetchAccountTypeLimits();
      if (limits.isNotEmpty) {
        AppConstants.updateAccountTypeLimits(limits);
        return AppConstants.accountTypeLimits;
      }
    } catch (_) {
      // Swallow and fall through to fallback.
    }

    final fallback = await _loadFallbackFromAsset();
    if (fallback.isNotEmpty) {
      AppConstants.updateAccountTypeLimits(fallback);
    }
    return AppConstants.accountTypeLimits;
  }

  Future<Map<String, double>> _loadFallbackFromAsset() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/config/system_limits_fallback.json',
      );
      final decoded = jsonDecode(jsonStr);
      final data = decoded is Map ? decoded['data'] : null;
      return _extractLimitsFromData(data);
    } catch (_) {
      return {};
    }
  }

  Map<String, double> _extractLimitsFromData(dynamic data) {
    final limits = <String, double>{};

    if (data is List) {
      for (final raw in data) {
        if (raw is Map) {
          final name = raw['account_name']?.toString();
          final value = raw['daily_limit'];
          final parsedLimit =
              value is num ? value.toDouble() : double.tryParse('$value');

          if (name != null && parsedLimit != null) {
            limits[name] = parsedLimit;
          }
        }
      }
    }

    return limits;
  }
}
