// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_suggestion_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SplitSuggestion _$SplitSuggestionFromJson(Map<String, dynamic> json) =>
    SplitSuggestion(
      accountType: json['accountType'] as String,
      amount: (json['amount'] as num).toInt(),
      accountIdentifier: json['accountIdentifier'] as String,
      priority: (json['priority'] as num).toInt(),
    );

Map<String, dynamic> _$SplitSuggestionToJson(SplitSuggestion instance) =>
    <String, dynamic>{
      'accountType': instance.accountType,
      'amount': instance.amount,
      'accountIdentifier': instance.accountIdentifier,
      'priority': instance.priority,
    };
