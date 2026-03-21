/// Lightweight view models for the cascading add-account flow.
class CountryOption {
  final String id;
  final String name;
  final String code;
  final bool isActive;

  const CountryOption({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
  });

  factory CountryOption.fromJson(Map<String, dynamic> json) {
    return CountryOption(
      id: json['id']?.toString() ?? '',
      name: json['country_name']?.toString() ?? '',
      code: json['country_code']?.toString() ?? '',
      isActive: json['is_active'] != false,
    );
  }
}

class AccountTypeOption {
  final String id;
  final String type;

  const AccountTypeOption({required this.id, required this.type});

  factory AccountTypeOption.fromJson(Map<String, dynamic> json) {
    return AccountTypeOption(
      id:
          json['account_type']?['id']?.toString() ??
          json['id']?.toString() ??
          '',
      type:
          json['account_type']?['type']?.toString() ??
          json['type']?.toString() ??
          '',
    );
  }
}

class ProviderOption {
  final String id;
  final String name;
  final String? logo;
  final bool isActive;

  const ProviderOption({
    required this.id,
    required this.name,
    this.logo,
    this.isActive = true,
  });

  factory ProviderOption.fromJson(Map<String, dynamic> json) {
    final provider = json['provider'];
    if (provider is Map) {
      return ProviderOption(
        id: provider['id']?.toString() ?? '',
        name: provider['provider_name']?.toString() ?? '',
        logo: provider['logo']?.toString(),
        isActive: provider['is_active'] != false,
      );
    }
    return ProviderOption(
      id: json['id']?.toString() ?? provider?.toString() ?? '',
      name: json['provider_name']?.toString() ?? provider?.toString() ?? '',
      logo: json['logo']?.toString(),
      isActive: json['is_active'] != false,
    );
  }
}

class CurrencyOption {
  final String providerAvailabilityId;
  final String currency;

  const CurrencyOption({
    required this.providerAvailabilityId,
    required this.currency,
  });

  factory CurrencyOption.fromJson(Map<String, dynamic> json) {
    return CurrencyOption(
      providerAvailabilityId: json['id']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
    );
  }
}
