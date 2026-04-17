import 'package:json_annotation/json_annotation.dart';

part 'policy_model.g.dart';

/// Represents a policy document (Privacy Policy, Terms & Conditions, About, etc.)
/// Fetched from Directus policies table
@JsonSerializable()
class PolicyModel {
  /// Unique identifier (can be string or int from Directus)
  final dynamic id;

  /// Policy title (e.g., "Privacy Policy", "Terms of Service")
  final String title;

  /// Policy content in HTML format
  final String content;

  /// Policy type: 'privacy', 'terms', 'about'
  final String type;

  /// Publication status
  final String status;

  /// When the policy was created
  @JsonKey(name: 'created_at')
  final String? createdAt;

  /// When the policy was last updated
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  PolicyModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) =>
      _$PolicyModelFromJson(json);

  Map<String, dynamic> toJson() => _$PolicyModelToJson(this);

  @override
  String toString() =>
      'PolicyModel(id: $id, title: $title, type: $type, status: $status)';
}

/// Response wrapper for Directus API policies endpoint
@JsonSerializable()
class PoliciesResponse {
  @JsonKey(name: 'data')
  final List<PolicyModel> policies;

  PoliciesResponse({required this.policies});

  factory PoliciesResponse.fromJson(Map<String, dynamic> json) =>
      _$PoliciesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PoliciesResponseToJson(this);
}
