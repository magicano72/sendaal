import '../../services/api_client.dart';
import '../constants/app_constants.dart';
import '../models/financial_account_model.dart';

class AccountService {
  final ApiClient apiClient;

  AccountService(this.apiClient);

  /// Get all financial accounts for a user
  Future<List<Map<String, dynamic>>> getAccountsByUserId(String userId) async {
    try {
      final result = await apiClient.get(
        '/items/financial_accounts',
        queryParams: {
          'filter[user][_eq]': userId,
          'fields':
              '*,country.*,account_type.*,'
              'provider.id,provider.provider_name,provider.logo,provider.is_active,'
              'provider_availability.id,provider_availability.currency,'
              'provider_availability.account_type.*,created_at',
        },
      );

      if (result['data'] is List) {
        final list = List<Map<String, dynamic>>.from(result['data']);
        const order = {'high': 0, 'medium': 1, 'low': 2};
        list.sort((a, b) {
          final pa = order[(a['priority'] ?? 'medium').toString()] ?? 1;
          final pb = order[(b['priority'] ?? 'medium').toString()] ?? 1;
          if (pa != pb) return pa.compareTo(pb);
          final ca = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final cb = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return ca.compareTo(cb);
        });
        return list;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get limit for account type
  static int getLimitForType(String accountType) {
    final limit = AppConstants.limitForAccountType(accountType);
    return limit.toInt();
  }

  /// Calculate smart split suggestion
  /// Returns list of SplitSuggestion objects
  List<Map<String, dynamic>> calculateSplitSuggestion(
    int amount,
    List<Map<String, dynamic>> visibleAccounts,
  ) {
    if (visibleAccounts.isEmpty) {
      throw Exception('No visible accounts available');
    }

    // Calculate total available limit
    int totalLimit = 0;
    for (var account in visibleAccounts) {
      totalLimit += getLimitForType(account['type']);
    }

    if (amount > totalLimit) {
      throw Exception(
        'Amount exceeds total limits. Max: $totalLimit, Requested: $amount',
      );
    }

    // Sort by priority (ascending order means higher priority accounts first)
    final sortedAccounts = List<Map<String, dynamic>>.from(visibleAccounts);
    const priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
    sortedAccounts.sort(
      (a, b) {
        final pa =
            priorityOrder[(a['priority'] ?? 'medium').toString()] ?? 1;
        final pb =
            priorityOrder[(b['priority'] ?? 'medium').toString()] ?? 1;
        return pa.compareTo(pb);
      },
    );

    // Split amount across accounts
    final suggestions = <Map<String, dynamic>>[];
    int remainingAmount = amount;

    for (var account in sortedAccounts) {
      if (remainingAmount <= 0) break;

      final accountType = account['type'];
      final limit = getLimitForType(accountType);
      final amountForThisAccount = remainingAmount > limit
          ? limit
          : remainingAmount;

      if (amountForThisAccount > 0) {
        suggestions.add({
          'accountType': accountType,
          'amount': amountForThisAccount,
          'accountIdentifier': account['accountIdentifier'],
          'priority': account['priority'],
        });

        remainingAmount -= amountForThisAccount;
      }
    }

    if (remainingAmount > 0) {
      throw Exception(
        'Unable to split the full amount across available accounts',
      );
    }

    return suggestions;
  }

  /// Add new financial account
  Future<Map<String, dynamic>> addAccount({
    required String userId,
    required String providerAvailabilityId,
    required String countryId,
    required String providerId,
    required String accountTypeId,
    required String accountIdentifier,
    required String accountTitle,
    required double limit,
    AccountPriority priority = AccountPriority.medium,
  }) async {
    return await apiClient.post(
      '/items/financial_accounts',
      body: {
        'user': userId,
        'provider_availability': providerAvailabilityId,
        'country': countryId,
        'provider': providerId,
        'account_type': accountTypeId,
        'account_identifier': accountIdentifier,
        'account_title': accountTitle,
        'limit': limit,
        'priority': priorityToString(priority),
      },
    );
  }

  /// Update account visibility
  Future<Map<String, dynamic>> updateAccountVisibility(
    String accountId,
    bool isVisible,
  ) async {
    return await apiClient.patch(
      '/items/financial_accounts/$accountId',
      body: {'is_visible': isVisible},
    );
  }

  /// Update account priority
  Future<Map<String, dynamic>> updateAccountPriority(
    String accountId,
    AccountPriority priority,
  ) async {
    return await apiClient.patch(
      '/items/financial_accounts/$accountId',
      body: {'priority': priorityToString(priority)},
    );
  }
}
