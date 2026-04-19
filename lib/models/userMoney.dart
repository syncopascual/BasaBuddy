import 'package:json_annotation/json_annotation.dart';

part 'userMoney.g.dart';


@JsonSerializable()
class UserMoney {
  final int id;

  @JsonKey(name: 'user_id')
  final String userId;

  final int money;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  UserMoney({
    required this.id,
    required this.userId,
    required this.money,
    required this.updatedAt
  });

  factory UserMoney.fromJson(Map<String, dynamic> json) =>
      _$UserMoneyFromJson(json);

  Map<String, dynamic> toJson() => _$UserMoneyToJson(this);
}
