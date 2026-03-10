import 'package:json_annotation/json_annotation.dart';

part 'financial_account_model.g.dart';

@JsonSerializable()
class FinancialAccount {
  final String id;
  final String userId;
  final String type; // instapay, vodafone_cash, bank_account, telda, other
  final String accountIdentifier;
  final int defaultLimit;
  final int priority;
  final bool isVisible;

  FinancialAccount({
    required this.id,
    required this.userId,
    required this.type,
    required this.accountIdentifier,
    required this.defaultLimit,
    required this.priority,
    required this.isVisible,
  });

  factory FinancialAccount.fromJson(Map<String, dynamic> json) =>
      _$FinancialAccountFromJson(json);
  Map<String, dynamic> toJson() => _$FinancialAccountToJson(this);

  FinancialAccount copyWith({
    String? id,
    String? userId,
    String? type,
    String? accountIdentifier,
    int? defaultLimit,
    int? priority,
    bool? isVisible,
  }) {
    return FinancialAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      accountIdentifier: accountIdentifier ?? this.accountIdentifier,
      defaultLimit: defaultLimit ?? this.defaultLimit,
      priority: priority ?? this.priority,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  /// Get type display name
  String getTypeName() {
    switch (type.toLowerCase()) {
      case 'instapay':
        return 'Instapay';
      case 'vodafone_cash':
        return 'Vodafone Cash';
      case 'bank_account':
        return 'Bank Account';
      case 'telda':
        return 'Telda';
      default:
        return type;
    }
  }

  @override
  String toString() =>
      'FinancialAccount(id: $id, type: $type, accountIdentifier: $accountIdentifier)';
}
