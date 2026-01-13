import 'package:json_annotation/json_annotation.dart';

part 'mulcho.g.dart';

///A multiple choice question object
///contains: story_ID, page(?), question, choices, and correct answer

@JsonSerializable()
class Mulcho {
  final String id;
  @JsonKey(name: 'user_id')
  final String storyId;
  final int page;
  final String question;
  final List<String> choices;
  final String answer;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Mulcho({
    required this.id,
    required this.storyId,
    required this.page,
    required this.question,
    required this.choices,
    required this.answer,
    required this.createdAt,
  });

  factory Mulcho.fromJson(Map<String, dynamic> json) =>
      _$MulchoFromJson(json);

  Map<String, dynamic> toJson() => _$MulchoToJson(this);
}
