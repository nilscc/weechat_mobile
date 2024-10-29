import 'package:json_annotation/json_annotation.dart';

part 'version.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Version {
  final String weechatVersion;
  final String weechatVersionGit;
  final int weechatVersionNumber;
  final String relayApiVersion;
  final int relayApiVersionNumber;

  Version({
    required this.weechatVersion,
    required this.weechatVersionGit,
    required this.weechatVersionNumber,
    required this.relayApiVersion,
    required this.relayApiVersionNumber,
  });

  /// Connect the generated [_$VersionFromJson] function to the `fromJson`
  /// factory.
  factory Version.fromJson(Map<String, dynamic> json) =>
      _$VersionFromJson(json);

  /// Connect the generated [_$VersionToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$VersionToJson(this);
  
  @override
  String toString() => "$runtimeType ${toJson()}";
}
