// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mulcho.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mulcho _$MulchoFromJson(Map<String, dynamic> json) => Mulcho(
      id: (json['id'] as num).toInt(),
      storyId: json['story_id'] as String,
      question: json['question'] as String,
      choices: (json['choices'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
      answer: int.tryParse(json['answer'].toString()) ?? 0,
      tagalogQuestion: json['tagalog_question'] as String,
      tagalogChoices: Map<String, String>.from(json['tagalog_choices'] as Map),
      skill: json['skill'] as String,
      afterPage: int.tryParse(json['after_page'].toString()) ?? 0,
      isStandalone: json['is_standalone'].toString().toLowerCase() == 'true'
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
      'is_standalone': instance.isStandalone,
    };
