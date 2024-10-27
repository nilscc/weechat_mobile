import 'package:json_annotation/json_annotation.dart';
import 'package:weechat/relay/api/objects/nick.dart';

part 'nick_group.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class NickGroup {
  final int id;
  final int parentGroupId;
  final String name;
  final String colorName;
  final String color;
  final bool visible;
  final List<dynamic> groups;
  final List<Nick> nicks;

  NickGroup({
    required this.id,
    required this.parentGroupId,
    required this.name,
    required this.colorName,
    required this.color,
    required this.visible,
    required this.groups,
    required this.nicks,
  });

  /// Connect the generated [_$NickGroupFromJson] function to the `fromJson`
  /// factory.
  factory NickGroup.fromJson(Map<String, dynamic> json) =>
      _$NickGroupFromJson(json);

  /// Connect the generated [_$NickGroupToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$NickGroupToJson(this);
}
