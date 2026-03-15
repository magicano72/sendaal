/// Supported account types
enum AccountType {
  instapay,
  digital_wallet,
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
  final String accountTitle;
  final double defaultLimit;
  final int priority;
  final bool isVisible;

  const FinancialAccount({
    required this.id,
    required this.userId,
    required this.type,
    required this.accountIdentifier,
    this.accountTitle = '',
    required this.defaultLimit,
    this.priority = 0,
    this.isVisible = true,
  });

  factory FinancialAccount.fromJson(Map<String, dynamic> json) {
    // Handle type field - it may come as array ['wallet'] or string 'wallet'
    String typeValue = 'other';
    final typeField = json['type'];
    if (typeField is List && typeField.isNotEmpty) {
      typeValue = typeField[0].toString();
    } else if (typeField is String) {
      typeValue = typeField;
    }

    return FinancialAccount(
      id: json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? json['userId']?.toString() ?? '',
      type: AccountType.fromString(typeValue),
      accountIdentifier: json['account_identifier']?.toString() ?? '',
      accountTitle: json['account_title']?.toString() ?? '',
      defaultLimit: double.tryParse(json['limit']?.toString() ?? '0') ?? 0,
      priority: json['priority'] is int
          ? json['priority']
          : int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
      isVisible: json['is_visible'] != false && json['isVisible'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'user': userId,
      'type': type.name,
      'account_identifier': accountIdentifier,
      'account_title': accountTitle,
      'limit': defaultLimit,
      'priority': priority,
    };
    // Only include is_visible if it's false (true is the default)
    if (!isVisible) {
      json['is_visible'] = false;
    }
    return json;
  }

  FinancialAccount copyWith({
    String? id,
    String? userId,
    AccountType? type,
    String? accountIdentifier,
    String? accountTitle,
    double? defaultLimit,
    int? priority,
    bool? isVisible,
  }) => FinancialAccount(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    accountIdentifier: accountIdentifier ?? this.accountIdentifier,
    accountTitle: accountTitle ?? this.accountTitle,
    defaultLimit: defaultLimit ?? this.defaultLimit,
    priority: priority ?? this.priority,
    isVisible: isVisible ?? this.isVisible,
  );
}
