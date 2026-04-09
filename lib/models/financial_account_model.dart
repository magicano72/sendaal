import '../utils/date_utils.dart';

/// Supported account types
enum AccountType {
  fiat,
  crypto,
  point,
  // instapay,
  // digital_wallet,
  // bank_account,
  // telda,
  // fawry,
  other;

  static AccountType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'fiat':
        return AccountType.fiat;
      case 'crypto':
        return AccountType.crypto;
      case 'point':
        return AccountType.point;
      // case 'instapay':
      //   return AccountType.instapay;
      // case 'digital_wallet':
      // case 'digital wallet':
      //   return AccountType.digital_wallet;
      // case 'bank_account':
      // case 'bank account':
      //   return AccountType.bank_account;
      // case 'telda':
      //   return AccountType.telda;
      // case 'fawry':
      //   return AccountType.fawry;
      default:
        return AccountType.other;
    }
  }
}

enum AccountPriority { low, medium, high }

AccountPriority priorityFromString(String? value) {
  switch (value) {
    case 'high':
      return AccountPriority.high;
    case 'low':
      return AccountPriority.low;
    case 'medium':
    default:
      return AccountPriority.medium;
  }
}

String priorityToString(AccountPriority priority) {
  switch (priority) {
    case AccountPriority.high:
      return 'high';
    case AccountPriority.low:
      return 'low';
    case AccountPriority.medium:
      return 'medium';
  }
}

/// Financial account belonging to a user
class FinancialAccount {
  final String id;
  final String userId;
  final String countryId;
  final String? countryCode;
  final String? countryName;
  final String accountTypeId;
  final String accountTypeName;
  final String providerId;
  final String providerName;
  final String? providerLogo;
  final String providerAvailabilityId;
  final String? currency;
  final AccountType type;
  final String accountIdentifier;
  final String accountTitle;
  final double defaultLimit;
  final AccountPriority priority;
  final bool isVisible;
  final bool isFavourite;
  final DateTime? createdAt;

  const FinancialAccount({
    required this.id,
    required this.userId,
    required this.countryId,
    this.countryCode,
    this.countryName,
    required this.accountTypeId,
    required this.accountTypeName,
    required this.providerId,
    required this.providerName,
    this.providerLogo,
    required this.providerAvailabilityId,
    this.currency,
    required this.type,
    required this.accountIdentifier,
    this.accountTitle = '',
    required this.defaultLimit,
    this.priority = AccountPriority.medium,
    this.isVisible = true,
    this.isFavourite = false,
    this.createdAt,
  });

  factory FinancialAccount.fromJson(Map<String, dynamic> json) {
    String _extractId(dynamic value) {
      if (value is Map && value['id'] != null) return value['id'].toString();
      return value?.toString() ?? '';
    }

    String? _extractField(dynamic value, String key) {
      if (value is Map && value[key] != null) return value[key].toString();
      return null;
    }

    final rawAccountType = json['account_type'];
    final accountTypeId = _extractId(rawAccountType);
    final accountTypeName =
        _extractField(rawAccountType, 'type') ??
        (json['type'] is String ? json['type'] as String : '');

    final rawCountry = json['country'];
    final countryId = _extractId(rawCountry);
    final countryCode =
        _extractField(rawCountry, 'country_code') ??
        json['country_code']?.toString();
    final countryName =
        _extractField(rawCountry, 'country_name') ??
        json['country_name']?.toString();

    final rawProvider = json['provider'];
    final providerId = _extractId(rawProvider);
    final providerName =
        _extractField(rawProvider, 'provider_name') ??
        rawProvider?.toString() ??
        '';
    final providerLogo = _extractField(rawProvider, 'logo');

    final rawProviderAvailability = json['provider_availability'];
    final providerAvailabilityId = _extractId(rawProviderAvailability);
    final availabilityCurrency = rawProviderAvailability is Map
        ? rawProviderAvailability['currency']?.toString()
        : null;

    // Handle type field - it may come as array ['wallet'] or string 'wallet'
    String typeValue = accountTypeName.isNotEmpty ? accountTypeName : 'other';
    final typeField = json['type'];
    if (typeField is List && typeField.isNotEmpty) {
      typeValue = typeField[0].toString();
    } else if (typeField is String && accountTypeName.isEmpty) {
      typeValue = typeField;
    }

    return FinancialAccount(
      id: json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? json['userId']?.toString() ?? '',
      countryId: countryId,
      countryCode: countryCode,
      countryName: countryName,
      accountTypeId: accountTypeId,
      accountTypeName: accountTypeName.isNotEmpty ? accountTypeName : typeValue,
      providerId: providerId,
      providerName: providerName,
      providerLogo: providerLogo,
      providerAvailabilityId: providerAvailabilityId,
      currency: availabilityCurrency,
      type: AccountType.fromString(typeValue),
      accountIdentifier: json['account_identifier']?.toString() ?? '',
      accountTitle: json['account_title']?.toString() ?? '',
      defaultLimit: double.tryParse(json['limit']?.toString() ?? '0') ?? 0,
      priority: priorityFromString(json['priority']?.toString()),
      isVisible: json['is_visible'] != false && json['isVisible'] != false,
      isFavourite: json['is_favourite'] == true,
      createdAt: parseDirectusDate(json['created_at']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'user': userId,
      'country': countryId,
      'account_type': accountTypeId.isNotEmpty ? accountTypeId : type.name,
      'provider': providerId,
      'provider_availability': providerAvailabilityId,
      'type': accountTypeName.isNotEmpty ? accountTypeName : type.name,
      'account_identifier': accountIdentifier,
      'account_title': accountTitle,
      'limit': defaultLimit,
      'priority': priorityToString(priority),
      'is_favourite': isFavourite,
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
    String? countryId,
    String? countryCode,
    String? countryName,
    String? accountTypeId,
    String? accountTypeName,
    String? providerId,
    String? providerName,
    String? providerLogo,
    String? providerAvailabilityId,
    String? currency,
    AccountType? type,
    String? accountIdentifier,
    String? accountTitle,
    double? defaultLimit,
    AccountPriority? priority,
    bool? isVisible,
    bool? isFavourite,
    DateTime? createdAt,
  }) => FinancialAccount(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    countryId: countryId ?? this.countryId,
    countryCode: countryCode ?? this.countryCode,
    countryName: countryName ?? this.countryName,
    accountTypeId: accountTypeId ?? this.accountTypeId,
    accountTypeName: accountTypeName ?? this.accountTypeName,
    providerId: providerId ?? this.providerId,
    providerName: providerName ?? this.providerName,
    providerLogo: providerLogo ?? this.providerLogo,
    providerAvailabilityId:
        providerAvailabilityId ?? this.providerAvailabilityId,
    currency: currency ?? this.currency,
    type: type ?? this.type,
    accountIdentifier: accountIdentifier ?? this.accountIdentifier,
    accountTitle: accountTitle ?? this.accountTitle,
    defaultLimit: defaultLimit ?? this.defaultLimit,
    priority: priority ?? this.priority,
    isVisible: isVisible ?? this.isVisible,
    isFavourite: isFavourite ?? this.isFavourite,
    createdAt: createdAt ?? this.createdAt,
  );
}
