import '../services/api_client.dart';

/// Represents a payment system with its daily transfer limit and optional icon.
class SystemLimit {
  final int id;
  final String systemName;
  final int dailyLimit;
  final String? systemImage;

  const SystemLimit({
    required this.id,
    required this.systemName,
    required this.dailyLimit,
    this.systemImage,
  });

  factory SystemLimit.fromJson(Map<String, dynamic> json) {
    return SystemLimit(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      systemName: json['system_name']?.toString() ?? '',
      dailyLimit: json['daily_limit'] is int
          ? json['daily_limit'] as int
          : int.tryParse('${json['daily_limit']}') ?? 0,
      systemImage: json['system_image']?.toString(),
    );
  }

  /// Directus file URL built from the configured API base URL.
  String? get imageUrl {
    if (systemImage == null || systemImage!.isEmpty) return null;
    final base = ApiClient.instance.baseUrl;
    return '$base/assets/$systemImage';
  }
}
