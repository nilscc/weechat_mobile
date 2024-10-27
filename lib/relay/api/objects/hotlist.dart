import 'package:json_annotation/json_annotation.dart';

part 'hotlist.g.dart';

enum Priority {
  @JsonValue(0)
  low,
  @JsonValue(1)
  message,
  @JsonValue(2)
  private,
  @JsonValue(3)
  highlight,
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Hotlist {
  final Priority priority;
  final DateTime date;
  final int bufferId;
  final List<int> count;

  Hotlist({
    required this.priority,
    required this.date,
    required this.bufferId,
    required this.count,
  });

  /// Connect the generated [_$HotlistFromJson] function to the `fromJson`
  /// factory.
  factory Hotlist.fromJson(Map<String, dynamic> json) =>
      _$HotlistFromJson(json);

  /// Connect the generated [_$HotlistToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$HotlistToJson(this);
}
