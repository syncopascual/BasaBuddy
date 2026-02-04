import 'package:json_annotation/json_annotation.dart';

part 'fillBlankData.g.dart';

///A multiple choice question object
///contains: story_ID, page(?), question, choices, and correct answer

@JsonSerializable()
class FillBlankData {
  final int id;

  @JsonKey(name: 'story_id')
  final String storyId;


  @JsonKey(name: 'statement_1')
  final String statement1;

  @JsonKey(name: 'statement_2')
  final String statement2;

  final List<String> choices;

  final String answer;
  @JsonKey(name: 'after_page')
  final int afterPage;

  final String skill;



  FillBlankData({
    required this.id,
    required this.storyId,
    required this.statement1,
    required this.statement2,
    required this.choices,
    required this.answer,
    required this.skill,
    required this.afterPage
  });

  factory FillBlankData.fromJson(Map<String, dynamic> json) =>
      _$FillBlankDataFromJson(json);

  Map<String, dynamic> toJson() => _$FillBlankDataToJson(this);
}
