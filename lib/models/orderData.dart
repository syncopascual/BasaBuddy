import 'package:json_annotation/json_annotation.dart';

part 'orderData.g.dart';

///A multiple choice question object
///contains: story_ID, page(?), question, choices, and correct answer

@JsonSerializable()
class OrderData {
  final int id;

  @JsonKey(name: 'story_id')
  final String storyId;

  final Map<String, String> data;

  @JsonKey(name: 'tagalog_data')
  final Map<String, String> tagalogData;

  @JsonKey(name: 'after_page')
  final int afterPage;

  final String skill;

  @JsonKey(name: 'isStandalone', fromJson: _boolFromInt)
  final bool isStandalone;

  static bool _boolFromInt(dynamic value) {
    if (value is bool) return value;
    return value == 1;
  }

  OrderData({
    required this.id,
    required this.storyId,
    required this.data,
    required this.skill,
    required this.afterPage,
    required this.tagalogData,
    required this.isStandalone
  });

  factory OrderData.fromJson(Map<String, dynamic> json) =>
      _$OrderDataFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDataToJson(this);
}
