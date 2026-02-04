// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchingData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchingData _$MatchingDataFromJson(Map<String, dynamic> json) => MatchingData(
      id: (json['id'] as num).toInt(),
      storyId: json['story_id'] as String,
      afterPage: (json['after_page'] as num).toInt(),
      pairs: Map<String, String>.from(json['pairs'] as Map),
      skill: json['skill'] as String,
    );

Map<String, dynamic> _$MatchingDataToJson(MatchingData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'story_id': instance.storyId,
      'pairs': instance.pairs,
      'after_page': instance.afterPage,
      'skill': instance.skill,
    };
