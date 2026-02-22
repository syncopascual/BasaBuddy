import 'package:json_annotation/json_annotation.dart';
part 'classes.g.dart';

@JsonSerializable()
class Classes {
  final String id;

  final String name;
  final String year;

  @JsonKey(name: 'teacher_id')
  final String teacherId;

  @JsonKey(name: 'class_code')
  final String classCode;

  Classes({
    required this.id,
    required this.name,
    required this.year,
    required this.teacherId,
    required this.classCode
  });



  factory Classes.fromJson(Map<String, dynamic> json) =>
      _$ClassesFromJson(json);

  Map<String, dynamic> toJson() => _$ClassesToJson(this);
}
