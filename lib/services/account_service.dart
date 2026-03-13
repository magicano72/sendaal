import '../models/financial_account_model.dart';
import 'api_client.dart';
import 'endpoint.dart';

/// Manages financial account CRUD operations
class AccountService {
  final ApiClient _api;

  AccountService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient.instance;

  /// Fetch all accounts for a given user ID
  Future<List<FinancialAccount>> getAccountsForUser(String userId) async {
    final response = await _api.get(
      Endpoints.financialAccounts,
      queryParams: {'filter[user][_eq]': userId},
    );
    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => FinancialAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Toggle account visibility
  Future<FinancialAccount> updateVisibility(
    String accountId,
    bool isVisible,
  ) async {
    final response = await _api.patch(
      '${Endpoints.financialAccounts}/$accountId',
      body: {'is_visible': isVisible},
    );
    return FinancialAccount.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Update account priority (star / reorder)
  Future<FinancialAccount> updatePriority(
    String accountId,
    int priority,
  ) async {
    final response = await _api.patch(
      '${Endpoints.financialAccounts}/$accountId',
      body: {'priority': priority},
    );
    return FinancialAccount.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Create a new financial account
  Future<FinancialAccount> createAccount({
    required String userId,
    required String type,
    required String accountIdentifier,
    required double defaultLimit,
    int priority = 0,
    bool isVisible = true,
  }) async {
    final body = {
      'user': userId,
      'type': type, // API now expects type as a string, not an array
      'account_identifier': accountIdentifier,
      'default_limit': defaultLimit,
      'priority': priority,
      'created_at': DateTime.now().toIso8601String().split(
        'T',
      )[0], // Format: YYYY-MM-DD
    };
    // Only include is_visible if it's false (true is the default)
    if (!isVisible) {
      body['is_visible'] = false;
    }

    final response = await _api.post(Endpoints.financialAccounts, body: body);
    return FinancialAccount.fromJson(response['data'] as Map<String, dynamic>);
  }
}
