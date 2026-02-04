// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fillBlankData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FillBlankData _$FillBlankDataFromJson(Map<String, dynamic> json) =>
    FillBlankData(
      id: (json['id'] as num).toInt(),
      storyId: json['story_id'] as String,
      statement1: json['statement_1'] as String,
      statement2: json['statement_2'] as String,
      choices:
          (json['choices'] as List<dynamic>).map((e) => e as String).toList(),
      answer: json['answer'] as String,
      skill: json['skill'] as String,
      afterPage: (json['after_page'] as num).toInt(),
    );

Map<String, dynamic> _$FillBlankDataToJson(FillBlankData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'story_id': instance.storyId,
      'statement_1': instance.statement1,
      'statement_2': instance.statement2,
      'choices': instance.choices,
      'answer': instance.answer,
      'after_page': instance.afterPage,
      'skill': instance.skill,
    };
