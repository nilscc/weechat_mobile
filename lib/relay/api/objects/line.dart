import 'package:json_annotation/json_annotation.dart';

part "line.g.dart";

enum NotifyLevel {
  @JsonValue(-1)
  noNotify,
  @JsonValue(0)
  low,
  @JsonValue(1)
  message,
  @JsonValue(2)
  privateMessage,
  @JsonValue(3)
  messageWithHighlight,
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Line {
  final int id;
  final int y;
  final DateTime date;
  final DateTime datePrinted;
  final bool highlight;
  final NotifyLevel notifyLevel;
  final String prefix;
  final String message;
  final List<String> tags;

  Line({
    required this.id,
    required this.y,
    required this.date,
    required this.datePrinted,
    required this.highlight,
    required this.notifyLevel,
    required this.prefix,
    required this.message,
    required this.tags,
  });

  /// Connect the generated [_$LineFromJson] function to the `fromJson`
  /// factory.
  factory Line.fromJson(Map<String, dynamic> json) =>
      _$LineFromJson(json);

  /// Connect the generated [_$LineToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$LineToJson(this);
}
