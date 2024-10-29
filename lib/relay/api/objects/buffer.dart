import 'package:json_annotation/json_annotation.dart';

part 'buffer.g.dart';

enum BufferType {
  formatted,
  free,
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Buffer {
  final int id;
  final String name;
  final String shortName;
  final int number;
  final BufferType type;
  final bool hidden;
  final String title;
  final String modes;
  final String inputPrompt;
  final String input;
  final int inputPosition;
  final bool inputMultiline;
  final bool nicklist;
  final bool nicklistCaseSensitive;
  final bool timeDisplayed;
  final Map<String, dynamic> localVariables;
  final List<Map<String, String>> keys;

  Buffer({
    required this.id,
    required this.name,
    required this.shortName,
    required this.number,
    required this.type,
    required this.hidden,
    required this.title,
    required this.modes,
    required this.inputPrompt,
    required this.input,
    required this.inputPosition,
    required this.inputMultiline,
    required this.nicklist,
    required this.nicklistCaseSensitive,
    required this.timeDisplayed,
    required this.localVariables,
    required this.keys,
  });

  /// Connect the generated [_$ApiBufferFromJson] function to the `fromJson`
  /// factory.
  factory Buffer.fromJson(Map<String, dynamic> json) =>
      _$ApiBufferFromJson(json);

  /// Connect the generated [_$ApiBufferToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$ApiBufferToJson(this);
}
