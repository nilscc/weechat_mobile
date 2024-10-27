import 'package:json_annotation/json_annotation.dart';

part 'nick.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Nick {
  final int id;
  final int parentGroupId;
  final String prefix;
  final String prefixColorName;
  final String prefixColor;
  final String name;
  final String colorName;
  final String color;
  final bool visible;

  Nick({
    required this.id,
    required this.parentGroupId,
    required this.prefix,
    required this.prefixColorName,
    required this.prefixColor,
    required this.name,
    required this.colorName,
    required this.color,
    required this.visible,
  });

  /// Connect the generated [_$NickFromJson] function to the `fromJson`
  /// factory.
  factory Nick.fromJson(Map<String, dynamic> json) =>
      _$NickFromJson(json);

  /// Connect the generated [_$NickToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$NickToJson(this);
}
