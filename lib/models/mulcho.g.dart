// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mulcho.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mulcho _$MulchoFromJson(Map<String, dynamic> json) => Mulcho(
      id: (json['id'] as num).toInt(),
      storyId: json['story_id'] as String,
      question: json['question'] as String,
      choices: Map<String, String>.from(json['choices'] as Map),
      answer: Mulcho._answerFromDynamic(json['answer']),
      tagalogQuestion: Mulcho._nullableString(json['tagalog_question']),
      tagalogChoices: Mulcho._nullableMap(json['tagalog_choices']),
      skill: json['skill'] as String,
      afterPage: (json['after_page'] as num).toInt(),
      isStandalone: Mulcho._boolFromInt(json['is_standalone']),
      hint: Mulcho._stringOrEmpty(json['hint']),
      explanation: Mulcho._stringOrEmpty(json['explanation']),
    );

Map<String, dynamic> _$MulchoToJson(Mulcho instance) => <String, dynamic>{
      'id': instance.id,
      'story_id': instance.storyId,
      'question': instance.question,
      'choices': instance.choices,
      'answer': Mulcho._answerToString(instance.answer),
      'tagalog_question': instance.tagalogQuestion,
      'tagalog_choices': instance.tagalogChoices,
      'hint': instance.hint,
      'explanation': instance.explanation,
      'after_page': instance.afterPage,
      'skill': instance.skill,
      'is_standalone': instance.isStandalone,
    };
