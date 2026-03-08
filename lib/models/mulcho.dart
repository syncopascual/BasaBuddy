import 'package:json_annotation/json_annotation.dart';

part 'mulcho.g.dart';

///A multiple choice question object
///contains: story_ID, page(?), question, choices, and correct answer

@JsonSerializable()
class Mulcho {
  final int id;

  @JsonKey(name: 'story_id')
  final String storyId;

  final String question;

  final Map<String, String> choices;

  @JsonKey(name: 'tagalog_question')
  final String tagalogQuestion;

  @JsonKey(name: 'tagalog_choices')
  final Map<String, String> tagalogChoices;

  final int answer;

  @JsonKey(name: 'after_page')
  final int afterPage;

  final String skill;


  Mulcho({
    required this.id,
    required this.storyId,
    required this.question,
    required this.choices,
    required this.answer,
    required this.tagalogQuestion,
    required this.tagalogChoices,
    required this.skill,
    required this.afterPage
  });

  factory Mulcho.fromJson(Map<String, dynamic> json) =>
      _$MulchoFromJson(json);

  Map<String, dynamic> toJson() => _$MulchoToJson(this);
}
