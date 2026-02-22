// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Classes _$ClassesFromJson(Map<String, dynamic> json) => Classes(
      id: json['id'] as String,
      name: json['name'] as String,
      year: json['year'] as String,
      teacherId: json['teacher_id'] as String,
      classCode: json['class_code'] as String,
    );

Map<String, dynamic> _$ClassesToJson(Classes instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'year': instance.year,
      'teacher_id': instance.teacherId,
      'class_code': instance.classCode,
    };
