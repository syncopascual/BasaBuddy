import 'package:json_annotation/json_annotation.dart';

part 'matchingData.g.dart';

///A multiple choice question object
///contains: story_ID, page(?), question, choices, and correct answer

@JsonSerializable()
class MatchingData {
  final int id;

  @JsonKey(name: 'story_id')
  final String storyId;

  final Map<String, String> pairs;

  @JsonKey(name: 'after_page')
  final int afterPage;



  final String skill;
  final bool isStandalone;

  MatchingData({
    required this.id,
    required this.storyId,
    required this.afterPage,
    required this.pairs,
    required this.skill,
    required this.isStandalone
  });

  factory MatchingData.fromJson(Map<String, dynamic> json) =>
      _$MatchingDataFromJson(json);

  Map<String, dynamic> toJson() => _$MatchingDataToJson(this);
}
