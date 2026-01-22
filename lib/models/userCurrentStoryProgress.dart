import 'package:json_annotation/json_annotation.dart';

part 'userCurrentStoryProgress.g.dart';


@JsonSerializable()
class UserCurrentStoryProgress {
  final int id;

  @JsonKey(name: 'user_id')
  final String userId;

  final String module;

  @JsonKey(name: 'story_id')
  final String storyId;

  final int page;




  UserCurrentStoryProgress({
    required this.id,
    required this.userId,
    required this.module,
    required this.storyId,
    required this.page
  });

  factory UserCurrentStoryProgress.fromJson(Map<String, dynamic> json) =>
      _$UserCurrentStoryProgressFromJson(json);

  Map<String, dynamic> toJson() => _$UserCurrentStoryProgressToJson(this);
}
