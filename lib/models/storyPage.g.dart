// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storyPage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Storypage _$StorypageFromJson(Map<String, dynamic> json) => Storypage(
      id: (json['id'] as num).toInt(),
      storyId: json['story_id'] as String,
      pageNum: (json['page_num'] as num).toInt(),
      text: json['text'] as String,
    );

Map<String, dynamic> _$StorypageToJson(Storypage instance) => <String, dynamic>{
      'id': instance.id,
      'story_id': instance.storyId,
      'page_num': instance.pageNum,
      'text': instance.text,
    };
