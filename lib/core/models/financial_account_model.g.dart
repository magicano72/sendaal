// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FinancialAccount _$FinancialAccountFromJson(Map<String, dynamic> json) =>
    FinancialAccount(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      accountIdentifier: json['accountIdentifier'] as String,
      defaultLimit: (json['defaultLimit'] as num).toInt(),
      priority: (json['priority'] as num).toInt(),
      isVisible: json['isVisible'] as bool,
    );

Map<String, dynamic> _$FinancialAccountToJson(FinancialAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': instance.type,
      'accountIdentifier': instance.accountIdentifier,
      'defaultLimit': instance.defaultLimit,
      'priority': instance.priority,
      'isVisible': instance.isVisible,
    };
