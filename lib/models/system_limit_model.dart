import '../services/api_client.dart';
import '../utils/date_utils.dart';

/// Represents a system/account-type limit as stored in Directus.
///
/// Directus `system_limits` fields:
/// - id (int)
/// - country (m2o -> countries)
/// - provider (m2o -> providers)
/// - account_type (m2o -> account_types)
/// - default_limit (float)
/// - created_at / updated_at
class SystemLimit {
  final int id;
  final String? countryId;
  final String? providerId;
  final String? accountTypeId;
  final String systemName; // derived from account_type.type for UI compatibility
  final double dailyLimit; // maps default_limit
  final String? systemImage; // currently unused in Directus; kept for compatibility
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SystemLimit({
    required this.id,
    required this.systemName,
    required this.dailyLimit,
    this.countryId,
    this.providerId,
    this.accountTypeId,
    this.systemImage,
    this.createdAt,
    this.updatedAt,
  });

  factory SystemLimit.fromJson(Map<String, dynamic> json) {
    String? _extractId(dynamic value) {
      if (value is Map && value['id'] != null) return value['id'].toString();
      return value?.toString();
    }

    String _extractType(dynamic value) {
      if (value is Map && value['type'] != null) {
        return value['type'].toString();
      }
      return value?.toString() ?? '';
    }

    final accountType = json['account_type'];
    final limit = double.tryParse(json['default_limit']?.toString() ?? '') ??
        double.tryParse(json['daily_limit']?.toString() ?? '') ??
        0;
    final rawSystemName =
        _extractType(accountType).isNotEmpty ? _extractType(accountType) : json['system_name']?.toString() ?? '';

    return SystemLimit(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      countryId: _extractId(json['country']),
      providerId: _extractId(json['provider']),
      accountTypeId: _extractId(accountType),
      systemName: rawSystemName,
      dailyLimit: limit,
      systemImage: json['system_image']?.toString(),
      createdAt: parseDirectusDate(json['created_at']?.toString()),
      updatedAt: parseDirectusDate(json['updated_at']?.toString()),
    );
  }

  /// Directus file URL built from the configured API base URL.
  String? get imageUrl {
    if (systemImage == null || systemImage!.isEmpty) return null;
    final base = ApiClient.instance.baseUrl;
    return '$base/assets/$systemImage';
  }
}
