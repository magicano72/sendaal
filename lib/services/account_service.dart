import '../models/account_selection_models.dart';
import '../models/financial_account_model.dart';
import 'api_client.dart';
import 'endpoint.dart';

/// Manages financial account CRUD operations
class AccountService {
  final ApiClient _api;
  static const String _accountFields =
      '*,country.*,account_type.*,'
      'provider.id,provider.provider_name,provider.logo,provider.is_active,'
      'provider_availability.id,provider_availability.currency,'
      'provider_availability.account_type.*';

  AccountService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient.instance;

  Future<FinancialAccount> getAccountById(String accountId) async {
    final response = await _api.get(
      '${Endpoints.financialAccounts}/$accountId',
      queryParams: {'fields': '$_accountFields,created_at'},
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return FinancialAccount.fromJson(data);
  }

  /// Fetch all accounts for a given user ID
  Future<List<FinancialAccount>> getAccountsForUser(String userId) async {
    final response = await _api.get(
      Endpoints.financialAccounts,
      queryParams: {
        'filter[user][_eq]': userId,
        'fields': '$_accountFields,created_at',
        'sort[]': 'created_at',
      },
    );
    final list = response['data'] as List<dynamic>? ?? [];
    final accounts = list
        .map((e) => FinancialAccount.fromJson(e as Map<String, dynamic>))
        .toList();

    const order = {'high': 0, 'medium': 1, 'low': 2};
    accounts.sort((a, b) {
      final pa = order[a.priority.name] ?? 1;
      final pb = order[b.priority.name] ?? 1;
      if (pa != pb) return pa.compareTo(pb);
      final ca = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final cb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return ca.compareTo(cb);
    });
    return accounts;
  }

  /// Step 1 — Get active countries
  Future<List<CountryOption>> getActiveCountries() async {
    final response = await _api.get(
      Endpoints.countries,
      queryParams: {
        'fields': 'id,country_name,country_code,is_active',
        'filter[is_active][_eq]': 'true',
      },
    );
    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => CountryOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Step 2 — Get account types by country
  Future<List<AccountTypeOption>> getAccountTypesForCountry(
    String countryId,
  ) async {
    final response = await _api.get(
      Endpoints.providerAvailability,
      queryParams: {
        'fields': 'account_type.id,account_type.type',
        'filter[country][_eq]': countryId,
      },
    );

    final list = response['data'] as List<dynamic>? ?? [];
    final mapped = list
        .map((e) => AccountTypeOption.fromJson(e as Map<String, dynamic>))
        .where((opt) => opt.id.isNotEmpty && opt.type.isNotEmpty);

    final deduped = <String, AccountTypeOption>{};
    for (final option in mapped) {
      deduped.putIfAbsent(option.id, () => option);
    }
    return deduped.values.toList();
  }

  /// Step 3 — Get providers by country + account type
  Future<List<ProviderOption>> getProviders({
    required String countryId,
    required String accountTypeId,
  }) async {
    final response = await _api.get(
      Endpoints.providerAvailability,
      queryParams: {
        'fields':
            'provider.id,provider.provider_name,provider.logo,provider.is_active',
        'filter[country][_eq]': countryId,
        'filter[account_type][_eq]': accountTypeId,
        'filter[is_active][_eq]': 'true',
      },
    );

    final list = response['data'] as List<dynamic>? ?? [];
    final mapped = list
        .map((e) => ProviderOption.fromJson(e as Map<String, dynamic>))
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty && p.isActive);

    final deduped = <String, ProviderOption>{};
    for (final provider in mapped) {
      deduped.putIfAbsent(provider.id, () => provider);
    }
    return deduped.values.toList();
  }

  /// Step 4 — Get currencies by country + account type + provider
  Future<List<CurrencyOption>> getCurrencies({
    required String countryId,
    required String accountTypeId,
    required String providerId,
  }) async {
    final response = await _api.get(
      Endpoints.providerAvailability,
      queryParams: {
        'fields': 'id,currency',
        'filter[country][_eq]': countryId,
        'filter[account_type][_eq]': accountTypeId,
        'filter[provider][_eq]': providerId,
        'filter[is_active][_eq]': 'true',
      },
    );

    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => CurrencyOption.fromJson(e as Map<String, dynamic>))
        .where((c) => c.currency.isNotEmpty)
        .toList();
  }

  /// Step 5 — Get default limit
  Future<double?> fetchDefaultLimit({
    required String countryId,
    required String accountTypeId,
    required String providerId,
  }) async {
    final response = await _api.get(
      Endpoints.systemLimits,
      queryParams: {
        'fields': 'id,default_limit',
        'filter[country][_eq]': countryId,
        'filter[account_type][_eq]': accountTypeId,
        'filter[provider][_eq]': providerId,
      },
    );

    final data = response['data'];
    if (data is List && data.isNotEmpty && data.first is Map) {
      final first = data.first as Map<String, dynamic>;
      final raw = first['default_limit'] ?? first['limit'];
      return double.tryParse(raw?.toString() ?? '');
    } else if (data is Map) {
      final raw = data['default_limit'] ?? data['limit'];
      return double.tryParse(raw?.toString() ?? '');
    }
    return null;
  }

  /// Toggle account visibility
  Future<FinancialAccount> updateVisibility(
    String accountId,
    bool isVisible,
  ) async {
    await _api.patch(
      '${Endpoints.financialAccounts}/$accountId',
      body: {'is_visible': isVisible},
    );
    return getAccountById(accountId);
  }

  /// Update account priority (star / reorder)
  Future<FinancialAccount> updatePriority(
    String accountId,
    AccountPriority priority,
  ) async {
    await _api.patch(
      '${Endpoints.financialAccounts}/$accountId',
      body: {'priority': priorityToString(priority)},
    );
    return getAccountById(accountId);
  }

  /// Create a new financial account
  Future<FinancialAccount> createAccount({
    required String userId,
    required String providerAvailabilityId,
    required String countryId,
    required String providerId,
    required String accountTypeId,
    required String accountIdentifier,
    required String accountTitle,
    required double limit,
    bool isVisible = true,
    AccountPriority priority = AccountPriority.medium,
  }) async {
    final body = {
      'user': userId,
      'provider_availability': providerAvailabilityId,
      'country': countryId,
      'provider': providerId,
      'account_type': accountTypeId,
      'account_identifier': accountIdentifier,
      'account_title': accountTitle,
      'limit': limit,
      'priority': priorityToString(priority),
    };
    // Only include is_visible if it's false (true is the default)
    if (!isVisible) {
      body['is_visible'] = false;
    }

    final response = await _api.post(Endpoints.financialAccounts, body: body);
    return FinancialAccount.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Update an existing financial account
  Future<FinancialAccount> updateAccount({
    required String accountId,
    required String providerAvailabilityId,
    required String countryId,
    required String providerId,
    required String accountTypeId,
    required String accountIdentifier,
    required String accountTitle,
    required double limit,
    AccountPriority? priority,
    bool isVisible = true,
  }) async {
    final body = <String, dynamic>{
      'provider_availability': providerAvailabilityId,
      'country': countryId,
      'provider': providerId,
      'account_type': accountTypeId,
      'account_identifier': accountIdentifier,
      'account_title': accountTitle,
      'limit': limit,
      if (priority != null) 'priority': priorityToString(priority),
      'is_visible': isVisible,
    };

    await _api.patch('${Endpoints.financialAccounts}/$accountId', body: body);
    return getAccountById(accountId);
  }

  /// Delete a financial account
  Future<void> deleteAccount(String accountId) async {
    await _api.delete('${Endpoints.financialAccounts}/$accountId');
  }
}
