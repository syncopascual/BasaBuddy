import 'package:json_annotation/json_annotation.dart';
part 'student.g.dart';
@JsonSerializable()
class Student {
  @JsonKey(name: 'id')
  final String studentId;

  final String name;

  Student({
    required this.studentId,
    required this.name
  });

  factory Student.fromJson(Map<String, dynamic> json) =>
      _$StudentFromJson(json);

  Map<String, dynamic> toJson() => _$StudentToJson(this);

  factory Student.fromSupabase(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>;
    return Student.fromJson(profile);
  }
}
