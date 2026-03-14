import '../../services/api_client.dart';
import '../constants/app_constants.dart';

class AccountService {
  final ApiClient apiClient;

  AccountService(this.apiClient);

  /// Get all financial accounts for a user
  Future<List<Map<String, dynamic>>> getAccountsByUserId(String userId) async {
    try {
      final result = await apiClient.get(
        '/items/financial_accounts',
        queryParams: {'filter[user][_eq]': userId},
      );

      if (result['data'] is List) {
        return List<Map<String, dynamic>>.from(result['data']);
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
    sortedAccounts.sort(
      (a, b) => (a['priority'] ?? 0).compareTo(b['priority'] ?? 0),
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
    required String type,
    required String accountIdentifier,
    required int priority,
    bool isVisible = true,
  }) async {
    return await apiClient.post(
      '/items/financial_accounts',
      body: {
        'user': userId,
        'type': type,
        'accountIdentifier': accountIdentifier,
        'defaultLimit': getLimitForType(type),
        'priority': priority,
        'isVisible': isVisible,
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
      body: {'isVisible': isVisible},
    );
  }

  /// Update account priority
  Future<Map<String, dynamic>> updateAccountPriority(
    String accountId,
    int priority,
  ) async {
    return await apiClient.patch(
      '/items/financial_accounts/$accountId',
      body: {'priority': priority},
    );
  }
}
