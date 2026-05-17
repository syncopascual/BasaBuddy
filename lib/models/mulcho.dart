import 'package:json_annotation/json_annotation.dart';

part 'mulcho.g.dart';

///A multiple choice question object
///contains: story_ID, page(?), question, choices, and correct answer
@JsonSerializable()
class Mulcho {
  final int id;

  @JsonKey(name: 'story_id')
  final String storyId;

  final String question;

  final Map<String, String> choices;

  @JsonKey(
      name: 'answer',
      fromJson: _answerFromDynamic,
      toJson: _answerToString) // ← updated
  final String answer;

  @JsonKey(name: 'tagalog_question', fromJson: _nullableString)
  final String? tagalogQuestion;

  @JsonKey(name: 'tagalog_choices', fromJson: _nullableMap)
  final Map<String, String>? tagalogChoices;

  @JsonKey(fromJson: _stringOrEmpty)
  final String hint;

  @JsonKey(fromJson: _stringOrEmpty)
  final String explanation;

  static String _stringOrEmpty(dynamic value) => value?.toString() ?? '';

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isEmpty) return null;
    return value.toString();
  }

  static Map<String, String>? _nullableMap(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isEmpty) return null;
    if (value is Map) return Map<String, String>.from(value);
    return null;
  }

  @JsonKey(name: 'after_page')
  final int afterPage;

  final String skill;

  @JsonKey(name: 'is_standalone', fromJson: _boolFromInt)
  final bool isStandalone;

  static String _answerFromDynamic(dynamic value) => value.toString();
  static String _answerToString(String value) => value;

  static bool _boolFromInt(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  Mulcho(
      {required this.id,
      required this.storyId,
      required this.question,
      required this.choices,
      required this.answer,
      this.tagalogQuestion,
      this.tagalogChoices,
      required this.skill,
      required this.afterPage,
      required this.isStandalone,
      required this.hint,
      required this.explanation});

  factory Mulcho.fromJson(Map<String, dynamic> json) => _$MulchoFromJson(json);
  Map<String, dynamic> toJson() => _$MulchoToJson(this);
}
