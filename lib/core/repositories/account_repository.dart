import '../error/exceptions.dart';
import '../models/financial_account_model.dart';
import '../models/split_suggestion_model.dart';
import '../services/account_service.dart';

class AccountRepository {
  final AccountService accountService;

  AccountRepository(this.accountService);

  Future<List<FinancialAccount>> getUserAccounts(String userId) async {
    try {
      final responses = await accountService.getAccountsByUserId(userId);
      return responses.map((data) => FinancialAccount.fromJson(data)).toList();
    } catch (e) {
      throw ApiException(message: 'Failed to fetch accounts: ${e.toString()}');
    }
  }

  /// Smart Split Algorithm
  /// Splits the amount across multiple accounts based on limits and priority
  List<SplitSuggestion> calculateSplit({
    required double amount,
    required List<FinancialAccount> accounts,
  }) {
    final suggestions = <SplitSuggestion>[];

    // Filter visible accounts and sort by priority
    final visibleAccounts = accounts.where((acc) => acc.isVisible).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    if (visibleAccounts.isEmpty) {
      throw ValidationException(message: 'No visible accounts available.');
    }

    double remainingAmount = amount;

    for (final account in visibleAccounts) {
      if (remainingAmount <= 0) break;

      final accountLimit = account.defaultLimit;
      final splitAmount = (remainingAmount > accountLimit)
          ? accountLimit
          : remainingAmount;

      suggestions.add(
        SplitSuggestion(
          type: account.type,
          amount: splitAmount.toDouble(),
          accountIdentifier: account.accountIdentifier,
        ),
      );

      remainingAmount -= splitAmount;
    }

    if (remainingAmount > 0) {
      throw ValidationException(
        message:
            'Amount exceeds total available limits. Max: ${_calculateTotalLimit(accounts)}',
      );
    }

    return suggestions;
  }

  /// Calculate total available limit across all accounts
  double _calculateTotalLimit(List<FinancialAccount> accounts) {
    return accounts.where((acc) => acc.isVisible).fold(0.0, (sum, acc) {
      return sum + acc.defaultLimit;
    }).toDouble();
  }
}
