import 'financial_account_model.dart';

/// Represents one line in a split payment suggestion
class SplitSuggestion {
  final AccountType type;
  final double amount;
  final String accountIdentifier;

  const SplitSuggestion({
    required this.type,
    required this.amount,
    required this.accountIdentifier,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'amount': amount,
        'accountIdentifier': accountIdentifier,
      };
}
