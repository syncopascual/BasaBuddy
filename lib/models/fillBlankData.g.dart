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
      tagalogStatement1: json['tagalog_statement_1'] as String,
      tagalogStatement2: json['tagalog_statement_2'] as String,
      tagalogChoices: (json['tagalog_choices'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tagalogAnswer: json['tagalog_answer'] as String,
      isStandalone: json['is_standalone'] as bool,
    );

Map<String, dynamic> _$FillBlankDataToJson(FillBlankData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'story_id': instance.storyId,
      'statement_1': instance.statement1,
      'statement_2': instance.statement2,
      'tagalog_statement_1': instance.tagalogStatement1,
      'tagalog_statement_2': instance.tagalogStatement2,
      'tagalog_choices': instance.tagalogChoices,
      'tagalog_answer': instance.tagalogAnswer,
      'choices': instance.choices,
      'answer': instance.answer,
      'after_page': instance.afterPage,
      'skill': instance.skill,
      'is_standalone': instance.isStandalone,
    };
