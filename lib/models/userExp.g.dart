// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'userExp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserExp _$UserExpFromJson(Map<String, dynamic> json) => UserExp(
      userId: json['user_id'] as String,
      narrativeExp: (json['narrative_exp'] as num).toInt(),
      vocabExp: (json['vocab_exp'] as num).toInt(),
      informationExp: (json['information_exp'] as num).toInt(),
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$UserExpToJson(UserExp instance) => <String, dynamic>{
      'user_id': instance.userId,
      'narrative_exp': instance.narrativeExp,
      'vocab_exp': instance.vocabExp,
      'information_exp': instance.informationExp,
      'updated_at': instance.updatedAt,
    };
