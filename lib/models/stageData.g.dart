// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stageData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StageData _$StageDataFromJson(Map<String, dynamic> json) => StageData(
      id: (json['id'] as num).toInt(),
      storyId: json['story_id'] as String,
      studentId: json['student_id'] as String,
      totalItems: (json['total_items'] as num).toInt(),
      totalAttempts: (json['total_attempts'] as num).toInt(),
      firstAttemptCorrect: (json['first_attempt_correct'] as num).toInt(),
      date: json['date'] as String,
      skill: json['skill'] as String,
    );

Map<String, dynamic> _$StageDataToJson(StageData instance) => <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'story_id': instance.storyId,
      'total_items': instance.totalItems,
      'total_attempts': instance.totalAttempts,
      'first_attempt_correct': instance.firstAttemptCorrect,
      'date': instance.date,
      'skill': instance.skill,
    };
