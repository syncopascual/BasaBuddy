// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'userCurrentStoryProgress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserCurrentStoryProgress _$UserCurrentStoryProgressFromJson(
        Map<String, dynamic> json) =>
    UserCurrentStoryProgress(
      id: (json['id'] as num).toInt(),
      userId: json['user_id'] as String,
      module: json['module'] as String,
      storyId: json['story_id'] as String,
      page: (json['page'] as num).toInt(),
    );

Map<String, dynamic> _$UserCurrentStoryProgressToJson(
        UserCurrentStoryProgress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'module': instance.module,
      'story_id': instance.storyId,
      'page': instance.page,
    };
