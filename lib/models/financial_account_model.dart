/// Supported account types
enum AccountType {
  instapay,
  vodafone_cash,
  bank_account,
  telda,
  other;

  static AccountType fromString(String value) {
    return AccountType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AccountType.other,
    );
  }
}

/// Financial account belonging to a user
class FinancialAccount {
  final String id;
  final String userId;
  final AccountType type;
  final String accountIdentifier;
  final double defaultLimit;
  final int priority;
  final bool isVisible;

  const FinancialAccount({
    required this.id,
    required this.userId,
    required this.type,
    required this.accountIdentifier,
    required this.defaultLimit,
    this.priority = 0,
    this.isVisible = true,
  });

  factory FinancialAccount.fromJson(Map<String, dynamic> json) =>
      FinancialAccount(
        id: json['id']?.toString() ?? '',
        userId: json['user']?.toString() ?? json['userId']?.toString() ?? '',
        type: AccountType.fromString(json['type']?.toString() ?? 'other'),
        accountIdentifier: json['account_identifier']?.toString() ??
            json['accountIdentifier']?.toString() ??
            '',
        defaultLimit:
            double.tryParse(json['default_limit']?.toString() ?? '0') ?? 0,
        priority: int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
        isVisible:
            json['is_visible'] != false && json['isVisible'] != false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': userId,
        'type': type.name,
        'account_identifier': accountIdentifier,
        'default_limit': defaultLimit,
        'priority': priority,
        'is_visible': isVisible,
      };

  FinancialAccount copyWith({
    String? id,
    String? userId,
    AccountType? type,
    String? accountIdentifier,
    double? defaultLimit,
    int? priority,
    bool? isVisible,
  }) =>
      FinancialAccount(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        accountIdentifier: accountIdentifier ?? this.accountIdentifier,
        defaultLimit: defaultLimit ?? this.defaultLimit,
        priority: priority ?? this.priority,
        isVisible: isVisible ?? this.isVisible,
      );
}
