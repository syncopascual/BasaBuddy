// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Story _$StoryFromJson(Map<String, dynamic> json) => Story(
      id: (json['id'] as num).toInt(),
      storyId: json['story_id'] as String,
      title: json['title'] as String,
      module: json['module'] as String,
      level: (json['level'] as num).toInt(),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$StoryToJson(Story instance) => <String, dynamic>{
      'id': instance.id,
      'story_id': instance.storyId,
      'title': instance.title,
      'module': instance.module,
      'level': instance.level,
      'description': instance.description,
    };
