import 'package:json_annotation/json_annotation.dart';

part 'userLevelInfo.g.dart';


@JsonSerializable()
class UserLevelInfo {
  final int? id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'vocab_lvl')
  final int vocabLevel;

  @JsonKey(name: 'narrative_lvl')
  final int narrativeLevel;

  @JsonKey(name: 'information_lvl')
  final int informationLevel;

  @JsonKey(name: 'updated_at')
  final String updatedAt;


  UserLevelInfo({
    this.id,
    required this.userId,
    required this.vocabLevel,
    required this.narrativeLevel,
    required this.informationLevel,
    required this.updatedAt
  });

  factory UserLevelInfo.fromJson(Map<String, dynamic> json) =>
      _$UserLevelInfoFromJson(json);

  Map<String, dynamic> toJson() => _$UserLevelInfoToJson(this);
}
