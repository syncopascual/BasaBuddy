import 'package:json_annotation/json_annotation.dart';

part 'storyPage.g.dart';

///A multiple choice question object
///contains: story_ID, page(?), question, choices, and correct answer

@JsonSerializable()
class Storypage {
  final int id;

  @JsonKey(name: 'story_id')
  final String storyId;

  @JsonKey(name: 'page_num')
  final int pageNum;

  final String text;


  Storypage({
    required this.id,
    required this.storyId,
    required this.pageNum,
    required this.text
  });

  factory Storypage.fromJson(Map<String, dynamic> json) =>
      _$StorypageFromJson(json);

  Map<String, dynamic> toJson() => _$StorypageToJson(this);
}
