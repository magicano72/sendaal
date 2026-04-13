import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/financial_account_model.dart';
import '../services/account_service.dart';
import 'access_request_provider.dart';
import 'auth_provider.dart';

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
      state = state.copyWith(isLoading: false, accounts: _sorted(accounts));
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
        accounts: _sorted(
          state.accounts.map((a) => a.id == accountId ? updated : a).toList(),
        ),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update account: $e');
    }
  }

  Future<FinancialAccount?> updateAccount({
    required String accountId,
    required String providerAvailabilityId,
    required String countryId,
    required String providerId,
    required String accountTypeId,
    required String accountIdentifier,
    required String accountTitle,
    required double limit,
    required AccountPriority priority,
    required bool isVisible,
  }) async {
    try {
      final updated = await _service.updateAccount(
        accountId: accountId,
        providerAvailabilityId: providerAvailabilityId,
        countryId: countryId,
        providerId: providerId,
        accountTypeId: accountTypeId,
        accountIdentifier: accountIdentifier,
        accountTitle: accountTitle,
        limit: limit,
        priority: priority,
        isVisible: isVisible,
      );

      state = state.copyWith(
        accounts: _sorted(
          state.accounts.map((a) => a.id == accountId ? updated : a).toList(),
        ),
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

  Future<void> updatePriority(
    String accountId,
    AccountPriority priority,
  ) async {
    try {
      final updated = await _service.updatePriority(accountId, priority);
      state = state.copyWith(
        accounts: _sorted(
          state.accounts.map((a) => a.id == accountId ? updated : a).toList(),
        ),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update priority: $e');
    }
  }

  Future<void> toggleFavourite(String accountId, bool current) async {
    final previous = state.accounts;
    final optimistic = _sorted(
      previous
          .map((a) => a.id == accountId ? a.copyWith(isFavourite: !current) : a)
          .toList(),
    );
    state = state.copyWith(accounts: optimistic);

    try {
      final updated = await _service.updateFavourite(accountId, !current);
      state = state.copyWith(
        accounts: _sorted(
          state.accounts.map((a) => a.id == accountId ? updated : a).toList(),
        ),
      );
    } catch (e) {
      state = state.copyWith(
        accounts: previous,
        error: 'Failed to update favourite: $e',
      );
    }
  }

  List<FinancialAccount> _sorted(List<FinancialAccount> list) {
    const order = {'high': 0, 'medium': 1, 'low': 2};
    list.sort((a, b) {
      if (a.isFavourite != b.isFavourite) {
        return a.isFavourite ? -1 : 1;
      }
      final pa = order[a.priority.name] ?? 1;
      final pb = order[b.priority.name] ?? 1;
      if (pa != pb) return pa.compareTo(pb);
      final ca = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final cb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return ca.compareTo(cb);
    });
    return list;
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

/// Fetch accounts for a user only when there is an approved access request
/// involving the current user (either requester or receiver).
final approvedAccountsProvider =
    FutureProvider.family<
      ({bool hasAccess, List<FinancialAccount> accounts}),
      String
    >((ref, userId) async {
      final currentUser = ref.watch(authProvider).user;
      if (currentUser == null) {
        return (hasAccess: false, accounts: <FinancialAccount>[]);
      }

      final accessService = ref.read(accessServiceProvider);
      final accountService = ref.read(accountServiceProvider);

      final approvedRequest = await accessService.getApprovedRequestBetween(
        userA: currentUser.id,
        userB: userId,
      );

      if (approvedRequest == null) {
        return (hasAccess: false, accounts: <FinancialAccount>[]);
      }

      final isRequester = approvedRequest.requesterId == currentUser.id;
      final targetUserId = isRequester
          ? approvedRequest.receiverId
          : approvedRequest.requesterId;

      // If access type is "full", return all accounts for the target user.
      final accessType = isRequester
          ? (approvedRequest.approvedAccessType ?? 'full')
          : (approvedRequest.requestAccessType.isNotEmpty
                ? approvedRequest.requestAccessType
                : 'full');

      if (accessType == 'full') {
        final accounts = await accountService.getAccountsForUser(targetUserId);
        return (hasAccess: true, accounts: accounts);
      }

      // Custom access: return only linked accounts for the relevant side.
      final side = isRequester ? 'receiver' : 'requester';
      final shared = await accessService.getRequestAccounts(
        accessRequestId: approvedRequest.id,
        side: side,
      );
      final accounts = shared
          .map((a) => a.financialAccount)
          .whereType<FinancialAccount>()
          .toList();
      return (hasAccess: true, accounts: accounts);
    });
