import 'package:json_annotation/json_annotation.dart';

part 'story.g.dart';

///A multiple choice question object
///contains: story_ID, page(?), question, choices, and correct answer

@JsonSerializable()
class Story {
  final int id;

  @JsonKey(name: 'story_id')
  final String storyId;

  final String title;
  final String module;
  final int level;

  final String? description;


  Story({
    required this.id,
    required this.storyId,
    required this.title,
    required this.module,
    required this.level,
    required this.description
  });

  factory Story.fromJson(Map<String, dynamic> json) =>
      _$StoryFromJson(json);

  Map<String, dynamic> toJson() => _$StoryToJson(this);
}
