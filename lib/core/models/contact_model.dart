import 'package:json_annotation/json_annotation.dart';

part 'contact_model.g.dart';

@JsonSerializable()
class Contact {
  final String id;
  final String userId;
  final String contactName;
  final String contactPhone;
  final String? matchedUserId;

  Contact({
    required this.id,
    required this.userId,
    required this.contactName,
    required this.contactPhone,
    this.matchedUserId,
  });

  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);
  Map<String, dynamic> toJson() => _$ContactToJson(this);

  Contact copyWith({
    String? id,
    String? userId,
    String? contactName,
    String? contactPhone,
    String? matchedUserId,
  }) {
    return Contact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      matchedUserId: matchedUserId ?? this.matchedUserId,
    );
  }

  @override
  String toString() =>
      'Contact(id: $id, contactName: $contactName, contactPhone: $contactPhone)';
}
