import '../core/models/split_suggestion_model.dart';
import '../models/financial_account_model.dart';

/// Result returned by the split engine
class SplitResult {
  final List<SplitSuggestion> suggestions;
  final String? error;

  bool get isSuccess => error == null;

  const SplitResult._({required this.suggestions, this.error});

  factory SplitResult.success(List<SplitSuggestion> suggestions) =>
      SplitResult._(suggestions: suggestions);

  factory SplitResult.failure(String error) =>
      SplitResult._(suggestions: [], error: error);
}

/// Smart Split Algorithm
///
/// Rules:
/// 1. Ignore hidden accounts
/// 2. Sort visible accounts by priority (ascending = higher priority first)
/// 3. Fill each account up to its defaultLimit until amount is fully covered
/// 4. Return error if amount exceeds the combined limit of all visible accounts
class SmartSplitService {
  /// Run the split algorithm and return a [SplitResult]
  static SplitResult split({
    required double amount,
    required List<FinancialAccount> accounts,
  }) {
    if (amount <= 0) {
      return SplitResult.failure('Amount must be greater than zero.');
    }

    // Filter out hidden accounts
    final visible = accounts.where((a) => a.isVisible).toList();

    if (visible.isEmpty) {
      return SplitResult.failure(
        'The recipient has no visible payment accounts.',
      );
    }

    // Sort by priority (lower number = higher priority)
    const order = {'high': 0, 'medium': 1, 'low': 2};
    visible.sort((a, b) {
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

    // Compute total capacity from limits stored in the DB
    final totalCapacity = visible.fold<double>(
      0,
      (sum, a) => sum + a.defaultLimit,
    );

    if (amount > totalCapacity) {
      return SplitResult.failure(
        'Amount (${_fmt(amount)}) exceeds the total transfer limit '
        '(${_fmt(totalCapacity)}) across all accounts.',
      );
    }

    // Distribute the amount greedily across accounts
    double remaining = amount;
    final suggestions = <SplitSuggestion>[];

    for (final account in visible) {
      if (remaining <= 0) break;

      // Use the account's stored defaultLimit as the cap for this account
      final allocated = remaining.clamp(0, account.defaultLimit.toDouble());

      suggestions.add(
        SplitSuggestion(
          type: account.type,
          amount: allocated.toDouble(),
          accountIdentifier: account.accountIdentifier,
        ),
      );

      remaining -= allocated;
    }

    return SplitResult.success(suggestions);
  }

  static String _fmt(double v) =>
      v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
}
