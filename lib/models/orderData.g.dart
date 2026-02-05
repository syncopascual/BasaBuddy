// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orderData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderData _$OrderDataFromJson(Map<String, dynamic> json) => OrderData(
      id: (json['id'] as num).toInt(),
      storyId: json['story_id'] as String,
      data: Map<String, String>.from(json['data'] as Map),
      skill: json['skill'] as String,
      afterPage: (json['after_page'] as num).toInt(),
      tagalogData: Map<String, String>.from(json['tagalog_data'] as Map),
    );

Map<String, dynamic> _$OrderDataToJson(OrderData instance) => <String, dynamic>{
      'id': instance.id,
      'story_id': instance.storyId,
      'data': instance.data,
      'tagalog_data': instance.tagalogData,
      'after_page': instance.afterPage,
      'skill': instance.skill,
    };
