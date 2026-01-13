// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mulcho.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mulcho _$MulchoFromJson(Map<String, dynamic> json) => Mulcho(
      id: json['id'] as String,
      storyId: json['user_id'] as String,
      page: (json['page'] as num).toInt(),
      question: json['question'] as String,
      choices:
          (json['choices'] as List<dynamic>).map((e) => e as String).toList(),
      answer: json['answer'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$MulchoToJson(Mulcho instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.storyId,
      'page': instance.page,
      'question': instance.question,
      'choices': instance.choices,
      'answer': instance.answer,
      'created_at': instance.createdAt.toIso8601String(),
    };
