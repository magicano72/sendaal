import 'package:json_annotation/json_annotation.dart';

part 'split_suggestion_model.g.dart';

@JsonSerializable()
class SplitSuggestion {
  final String accountType;
  final int amount;
  final String accountIdentifier;
  final int priority;

  SplitSuggestion({
    required this.accountType,
    required this.amount,
    required this.accountIdentifier,
    required this.priority,
  });

  factory SplitSuggestion.fromJson(Map<String, dynamic> json) =>
      _$SplitSuggestionFromJson(json);
  Map<String, dynamic> toJson() => _$SplitSuggestionToJson(this);

  SplitSuggestion copyWith({
    String? accountType,
    int? amount,
    String? accountIdentifier,
    int? priority,
  }) {
    return SplitSuggestion(
      accountType: accountType ?? this.accountType,
      amount: amount ?? this.amount,
      accountIdentifier: accountIdentifier ?? this.accountIdentifier,
      priority: priority ?? this.priority,
    );
  }

  @override
  String toString() =>
      'SplitSuggestion(accountType: $accountType, amount: $amount)';
}
