// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'userMoney.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserMoney _$UserMoneyFromJson(Map<String, dynamic> json) => UserMoney(
      id: (json['id'] as num).toInt(),
      userId: json['user_id'] as String,
      money: (json['money'] as num).toInt(),
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$UserMoneyToJson(UserMoney instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'money': instance.money,
      'updated_at': instance.updatedAt,
    };
