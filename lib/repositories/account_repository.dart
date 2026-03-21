import '../models/financial_account_model.dart';
import '../services/account_service.dart';

/// Repository for financial account data operations
class AccountRepository {
  final AccountService _service;

  AccountRepository({AccountService? service})
    : _service = service ?? AccountService();

  Future<List<FinancialAccount>> getAccountsForUser(String userId) =>
      _service.getAccountsForUser(userId);

  Future<FinancialAccount> toggleVisibility(String accountId, bool current) =>
      _service.updateVisibility(accountId, !current);

  Future<FinancialAccount> createAccount({
    required String userId,
    required String providerAvailabilityId,
    required String countryId,
    required String providerId,
    required String accountTypeId,
    required String identifier,
    required String title,
    required double limit,
    AccountPriority priority = AccountPriority.medium,
  }) => _service.createAccount(
    userId: userId,
    providerAvailabilityId: providerAvailabilityId,
    countryId: countryId,
    providerId: providerId,
    accountTypeId: accountTypeId,
    accountIdentifier: identifier,
    accountTitle: title,
    limit: limit,
    priority: priority,
  );
}
