import '../core/models/financial_account_model.dart';
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
    required String type,
    required String identifier,
    required double limit,
  }) => _service.createAccount(
    userId: userId,
    type: type,
    accountIdentifier: identifier,
    defaultLimit: limit,
  );
}
