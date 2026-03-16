import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../core/constants/app_constants.dart';
import '../models/system_limit_model.dart';
import 'api_client.dart';
import 'endpoint.dart';

/// Fetches system-wide account limits and caches them in [AppConstants].
class SystemLimitsService {
  final ApiClient _apiClient;
  List<SystemLimit> _cached = const [];

  SystemLimitsService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Retrieve system limits (with images) from the backend.
  Future<List<SystemLimit>> fetchSystemLimits() async {
    final response = await _apiClient.get(Endpoints.systemLimits);
    final data = response is Map ? response['data'] : null;
    final limits = _extractSystemLimitsFromData(data);
    if (limits.isNotEmpty) {
      _cached = limits;
      AppConstants.updateSystemLimits(limits);
    }
    return limits;
  }

  /// Legacy helper: returns a simple map keyed by system_name.
  Future<Map<String, double>> fetchAccountTypeLimits() async {
    final limits = await fetchSystemLimits();
    return _mapLimits(limits);
  }

  /// Load limits at app startup and persist them in memory with fallback asset.
  Future<Map<String, double>> loadAndCache() async {
    try {
      final limits = await fetchSystemLimits();
      if (limits.isNotEmpty) {
        AppConstants.updateAccountTypeLimits(_mapLimits(limits));
        AppConstants.updateSystemLimits(limits);
        return AppConstants.accountTypeLimits;
      }
    } catch (_) {
      // Swallow and fall through to fallback.
    }

    final fallbackLimits = await _loadFallbackFromAsset();
    if (fallbackLimits.isNotEmpty) {
      AppConstants.updateAccountTypeLimits(_mapLimits(fallbackLimits));
      AppConstants.updateSystemLimits(fallbackLimits);
      _cached = fallbackLimits;
    }
    return AppConstants.accountTypeLimits;
  }

  /// Load limits for UI use, preferring API then fallback, and caches the result.
  Future<List<SystemLimit>> loadLimits() async {
    try {
      final limits = await fetchSystemLimits();
      if (limits.isNotEmpty) return limits;
    } catch (_) {
      // ignore and fallback
    }
    final fallbackLimits = await _loadFallbackFromAsset();
    if (fallbackLimits.isNotEmpty) {
      AppConstants.updateSystemLimits(fallbackLimits);
    }
    _cached = fallbackLimits;
    return fallbackLimits;
  }

  /// Expose the most recently fetched system limits (API first, then fallback).
  List<SystemLimit> get cachedLimits => _cached;

  Future<List<SystemLimit>> _loadFallbackFromAsset() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/config/system_limits_fallback.json',
      );
      final decoded = jsonDecode(jsonStr);
      final data = decoded is Map ? decoded['data'] : null;
      return _extractSystemLimitsFromData(data);
    } catch (_) {
      return const [];
    }
  }

  List<SystemLimit> _extractSystemLimitsFromData(dynamic data) {
    final limits = <SystemLimit>[];

    if (data is List) {
      for (final raw in data) {
        if (raw is Map) {
          final map = raw.map((key, value) => MapEntry(key.toString(), value));
          limits.add(SystemLimit.fromJson(map));
        }
      }
    }

    return limits;
  }

  Map<String, double> _mapLimits(List<SystemLimit> limits) {
    final map = <String, double>{};
    for (final limit in limits) {
      map[limit.systemName] = limit.dailyLimit.toDouble();
    }
    return map;
  }
}
