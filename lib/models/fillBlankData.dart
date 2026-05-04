import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
part 'fillBlankData.g.dart';

///A multiple choice question object
///contains: story_ID, page(?), question, choices, and correct answer

@JsonSerializable()
class FillBlankData {
  final int id;

  @JsonKey(name: 'story_id')
  final String storyId;


  @JsonKey(name: 'statement_1')
  final String statement1;

  @JsonKey(name: 'statement_2')
  final String statement2;

  @JsonKey(name: 'tagalog_statement_1')
  final String tagalogStatement1;

  @JsonKey(name: 'tagalog_statement_2')
  final String tagalogStatement2;

  @JsonKey(name: 'tagalog_choices')
  final List<String> tagalogChoices;

  @JsonKey(name: 'tagalog_answer')
  final String tagalogAnswer;

  final List<String> choices;

  @JsonKey(fromJson: _stringOrEmpty)
  final String hint;

  @JsonKey(fromJson: _stringOrEmpty)
  final String explanation;

  static String _stringOrEmpty(dynamic value) => value?.toString() ?? '';

  final String answer;
  @JsonKey(name: 'after_page')
  final int afterPage;

  final String skill;

  @JsonKey(name: 'is_standalone', fromJson: _boolFromInt)
  final bool isStandalone;

  static bool _boolFromInt(dynamic value) {
    if (value is bool) return value;
    return value == 1;
  }

  FillBlankData({
    required this.id,
    required this.storyId,
    required this.statement1,
    required this.statement2,
    required this.choices,
    required this.answer,
    required this.skill,
    required this.afterPage,
    required this.tagalogStatement1,
    required this.tagalogStatement2,
    required this.tagalogChoices,
    required this.tagalogAnswer,
    required this.isStandalone,
    required this.hint,
    required this.explanation

  });

  factory FillBlankData.fromJson(Map<String, dynamic> json) {
    //print('DEBUG FillBlankData.fromJson: $json');

    // Decode list fields if they come back as raw JSON strings
    if (json['choices'] is String) {
      json['choices'] = jsonDecode(json['choices'] as String);
    }
    if (json['tagalog_choices'] is String) {
      json['tagalog_choices'] = jsonDecode(json['tagalog_choices'] as String);
    }

    return _$FillBlankDataFromJson(json);
  }

  Map<String, dynamic> toJson() => _$FillBlankDataToJson(this);
}
