import 'package:json_annotation/json_annotation.dart';

part 'stageData.g.dart';

///A multiple choice question object
///contains: story_ID, page(?), question, choices, and correct answer

@JsonSerializable()
class StageData {

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'story_id')
  final String storyId;

  @JsonKey(name: 'total_items')
  final int totalItems;

  @JsonKey(name: 'total_attempts')
  final int totalAttempts;

  @JsonKey(name: 'first_attempt_correct')
  final int firstAttemptCorrect;

  final String date;

  final String skill;


  StageData({
    required this.storyId,
    required this.userId,
    required this.totalItems,
    required this.totalAttempts,
    required this.firstAttemptCorrect,
    required this.date,
    required this.skill
  });

  factory StageData.fromJson(Map<String, dynamic> json) =>
      _$StageDataFromJson(json);

  Map<String, dynamic> toJson() => _$StageDataToJson(this);
}
