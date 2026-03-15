import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/financial_account_model.dart';
import '../services/account_service.dart';

final accountServiceProvider = Provider<AccountService>(
  (ref) => AccountService(),
);

/// State for the list of accounts (loading/error/data)
class AccountsState {
  final List<FinancialAccount> accounts;
  final bool isLoading;
  final String? error;

  const AccountsState({
    this.accounts = const [],
    this.isLoading = false,
    this.error,
  });

  AccountsState copyWith({
    List<FinancialAccount>? accounts,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => AccountsState(
    accounts: accounts ?? this.accounts,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
  );
}

class AccountsNotifier extends StateNotifier<AccountsState> {
  final AccountService _service;

  AccountsNotifier(this._service) : super(const AccountsState());

  Future<void> loadAccounts(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final accounts = await _service.getAccountsForUser(userId);
      state = state.copyWith(isLoading: false, accounts: accounts);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load accounts: $e',
      );
    }
  }

  Future<void> toggleVisibility(String accountId, bool current) async {
    try {
      final updated = await _service.updateVisibility(accountId, !current);
      state = state.copyWith(
        accounts: state.accounts
            .map((a) => a.id == accountId ? updated : a)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update account: $e');
    }
  }

  Future<FinancialAccount?> updateAccount({
    required String accountId,
    required String type,
    required String accountIdentifier,
    required String accountTitle,
    required double defaultLimit,
    required int priority,
    required bool isVisible,
  }) async {
    try {
      final updated = await _service.updateAccount(
        accountId: accountId,
        type: type,
        accountIdentifier: accountIdentifier,
        accountTitle: accountTitle,
        defaultLimit: defaultLimit,
        priority: priority,
        isVisible: isVisible,
      );

      state = state.copyWith(
        accounts: state.accounts
            .map((a) => a.id == accountId ? updated : a)
            .toList(),
      );

      return updated;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update account: $e');
      return null;
    }
  }

  Future<void> deleteAccount(String accountId) async {
    final previous = state.accounts;
    state = state.copyWith(
      accounts: previous.where((a) => a.id != accountId).toList(),
    );

    try {
      await _service.deleteAccount(accountId);
    } catch (e) {
      // Revert on failure
      state = state.copyWith(
        accounts: previous,
        error: 'Failed to delete account: $e',
      );
      rethrow;
    }
  }

  Future<void> updatePriority(String accountId, int priority) async {
    try {
      final updated = await _service.updatePriority(accountId, priority);
      state = state.copyWith(
        accounts: state.accounts
            .map((a) => a.id == accountId ? updated : a)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update priority: $e');
    }
  }
}

final accountsProvider = StateNotifierProvider<AccountsNotifier, AccountsState>(
  (ref) {
    return AccountsNotifier(ref.read(accountServiceProvider));
  },
);

/// Family provider for fetching accounts of a specific user (recipient view)
final recipientAccountsProvider =
    FutureProvider.family<List<FinancialAccount>, String>((ref, userId) async {
      final service = ref.read(accountServiceProvider);
      return service.getAccountsForUser(userId);
    });
