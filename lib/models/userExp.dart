import 'package:json_annotation/json_annotation.dart';

part 'userExp.g.dart';


@JsonSerializable()
class UserExp {

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'narrative_exp')
  final int narrativeExp;

  @JsonKey(name: 'vocab_exp')
  final int vocabExp;

  @JsonKey(name: 'information_exp')
  final int informationExp;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  UserExp({
    required this.userId,
    required this.narrativeExp,
    required this.vocabExp,
    required this.informationExp,
    required this.updatedAt,
  });

  factory UserExp.fromJson(Map<String, dynamic> json) =>
      _$UserExpFromJson(json);

  Map<String, dynamic> toJson() => _$UserExpToJson(this);
}
