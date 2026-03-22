import 'financial_account_model.dart';

/// Link table between access requests and the accounts shared by each side.
class AccessRequestAccount {
  final String id;
  final String accessRequestId;
  final FinancialAccount financialAccount;
  final String side; // "requester" | "receiver"

  const AccessRequestAccount({
    required this.id,
    required this.accessRequestId,
    required this.financialAccount,
    required this.side,
  });

  factory AccessRequestAccount.fromJson(Map<String, dynamic> json) {
    final financial = _parseFinancialAccount(json['financial_account']);

    return AccessRequestAccount(
      id: json['id']?.toString() ?? '',
      accessRequestId:
          json['access_request']?.toString() ?? json['accessRequest'] ?? '',
      financialAccount: financial,
      side: (json['side'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'access_request': accessRequestId,
        'financial_account': financialAccount.id,
        'side': side,
      };

  AccessRequestAccount copyWith({
    String? id,
    String? accessRequestId,
    FinancialAccount? financialAccount,
    String? side,
  }) =>
      AccessRequestAccount(
        id: id ?? this.id,
        accessRequestId: accessRequestId ?? this.accessRequestId,
        financialAccount: financialAccount ?? this.financialAccount,
        side: side ?? this.side,
      );

  static FinancialAccount _parseFinancialAccount(dynamic value) {
    if (value is Map<String, dynamic>) {
      return FinancialAccount.fromJson(value);
    }
    // Fallback minimal object when only ID is present; caller should refresh.
    return FinancialAccount(
      id: value?.toString() ?? '',
      userId: '',
      countryId: '',
      accountTypeId: '',
      accountTypeName: '',
      providerId: '',
      providerName: '',
      providerAvailabilityId: '',
      type: AccountType.other,
      accountIdentifier: '',
      defaultLimit: 0,
    );
  }
}
