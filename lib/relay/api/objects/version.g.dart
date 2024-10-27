// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Version _$VersionFromJson(Map<String, dynamic> json) => Version(
      weechatVersion: json['weechat_version'] as String,
      weechatVersionGit: json['weechat_version_git'] as String,
      weechatVersionNumber: (json['weechat_version_number'] as num).toInt(),
      relayApiVersion: json['relay_api_version'] as String,
      relayApiVersionNumber: (json['relay_api_version_number'] as num).toInt(),
    );

Map<String, dynamic> _$VersionToJson(Version instance) => <String, dynamic>{
      'weechat_version': instance.weechatVersion,
      'weechat_version_git': instance.weechatVersionGit,
      'weechat_version_number': instance.weechatVersionNumber,
      'relay_api_version': instance.relayApiVersion,
      'relay_api_version_number': instance.relayApiVersionNumber,
    };
