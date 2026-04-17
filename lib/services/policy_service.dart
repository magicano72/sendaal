import '../models/policy_model.dart';
import 'api_client.dart';

/// Service for fetching and caching policy documents from Directus
class PolicyService {
  final ApiClient _apiClient = ApiClient.instance;

  // Simple in-memory cache
  final Map<String, PolicyModel> _policyCache = {};
  final Map<String, DateTime> _cacheTimes = {};
  static const Duration _cacheDuration = Duration(hours: 24);

  /// Fetch a specific policy by type (privacy, terms, about)
  ///
  /// Returns the first published policy of the given type.
  /// Caches results for 24 hours.
  Future<PolicyModel?> getPolicyByType(String type) async {
    // Check cache first
    if (_policyCache.containsKey(type)) {
      final cacheTime = _cacheTimes[type];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheDuration) {
        return _policyCache[type];
      }
    }

    try {
      final response = await _apiClient
          .getPublic(
            '/items/policies',
            queryParams: {
              'filter[type][_eq]': type,
              'filter[status][_eq]': 'published',
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw const ApiException(
              'Policy fetch timeout. Please try again.',
            ),
          );

      final data = response['data'] as List<dynamic>? ?? [];
      if (data.isEmpty) {
        return null;
      }

      final policy = PolicyModel.fromJson(data.first as Map<String, dynamic>);

      // Cache it
      _policyCache[type] = policy;
      _cacheTimes[type] = DateTime.now();

      return policy;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to fetch $type policy: $e');
    }
  }

  /// Fetch privacy policy
  Future<PolicyModel?> getPrivacyPolicy() => getPolicyByType('privacy');

  /// Fetch terms of service
  Future<PolicyModel?> getTermsPolicy() => getPolicyByType('terms');

  /// Fetch about policy
  Future<PolicyModel?> getAboutPolicy() => getPolicyByType('about');

  /// Fetch all published policies of a given type
  /// Useful for admin dashboards showing policy history
  Future<List<PolicyModel>> getPoliciesByType(String type) async {
    try {
      final response = await _apiClient.getPublic(
        '/items/policies',
        queryParams: {
          'filter[type][_eq]': type,
          'filter[status][_eq]': 'published',
        },
      );

      final data = response['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => PolicyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to fetch policies: $e');
    }
  }

  /// Clear the policy cache
  void clearCache() {
    _policyCache.clear();
    _cacheTimes.clear();
  }

  /// Clear cache for specific policy type
  void clearCacheForType(String type) {
    _policyCache.remove(type);
    _cacheTimes.remove(type);
  }
}
