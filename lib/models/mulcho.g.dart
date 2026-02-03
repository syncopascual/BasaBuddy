// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mulcho.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mulcho _$MulchoFromJson(Map<String, dynamic> json) => Mulcho(
      id: (json['id'] as num).toInt(),
      storyId: json['story_id'] as String,
      afterPage: (json['after_page'] as num).toInt(),
      question: json['question'] as String,
      choices: Map<String, String>.from(json['choices'] as Map),
      answer: json['answer'] as String,
      tagalogQuestion: json['tagalog_question'] as String,
      tagalogChoices: Map<String, String>.from(json['tagalog_choices'] as Map),
      skill: json['skill'] as String,
    );

Map<String, dynamic> _$MulchoToJson(Mulcho instance) => <String, dynamic>{
      'id': instance.id,
      'story_id': instance.storyId,
      'question': instance.question,
      'choices': instance.choices,
      'tagalog_question': instance.tagalogQuestion,
      'tagalog_choices': instance.tagalogChoices,
      'answer': instance.answer,
      'after_page': instance.afterPage,
      'skill': instance.skill,
    };
