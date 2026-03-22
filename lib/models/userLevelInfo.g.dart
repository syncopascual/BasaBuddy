// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'userLevelInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserLevelInfo _$UserLevelInfoFromJson(Map<String, dynamic> json) =>
    UserLevelInfo(
      id: (json['id'] as num).toInt(),
      userId: json['user_id'] as String,
      vocabLevel: (json['vocab_lvl'] as num).toInt(),
      narrativeLevel: (json['narrative_lvl'] as num).toInt(),
      informationLevel: (json['information_lvl'] as num).toInt(),
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$UserLevelInfoToJson(UserLevelInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'vocab_lvl': instance.vocabLevel,
      'narrative_lvl': instance.narrativeLevel,
      'information_lvl': instance.informationLevel,
      'updated_at': instance.updatedAt,
    };
