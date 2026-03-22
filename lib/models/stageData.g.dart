// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stageData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StageData _$StageDataFromJson(Map<String, dynamic> json) => StageData(
      storyId: json['story_id'] as String,
      userId: json['user_id'] as String,
      totalItems: (json['total_items'] as num).toInt(),
      totalAttempts: (json['total_attempts'] as num).toInt(),
      firstAttemptCorrect: (json['first_attempt_correct'] as num).toInt(),
      date: json['date'] as String,
      skill: json['skill'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$StageDataToJson(StageData instance) => <String, dynamic>{
      'user_id': instance.userId,
      'story_id': instance.storyId,
      'total_items': instance.totalItems,
      'total_attempts': instance.totalAttempts,
      'first_attempt_correct': instance.firstAttemptCorrect,
      'date': instance.date,
      'updated_at': instance.updatedAt,
      'skill': instance.skill,
    };
