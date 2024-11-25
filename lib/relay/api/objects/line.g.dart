// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Line _$LineFromJson(Map<String, dynamic> json) => Line(
      id: (json['id'] as num).toInt(),
      y: (json['y'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      datePrinted: DateTime.parse(json['date_printed'] as String),
      highlight: json['highlight'] as bool,
      notifyLevel: $enumDecode(_$NotifyLevelEnumMap, json['notify_level']),
      prefix: json['prefix'] as String,
      message: json['message'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$LineToJson(Line instance) => <String, dynamic>{
      'id': instance.id,
      'y': instance.y,
      'date': instance.date.toIso8601String(),
      'date_printed': instance.datePrinted.toIso8601String(),
      'highlight': instance.highlight,
      'notify_level': _$NotifyLevelEnumMap[instance.notifyLevel]!,
      'prefix': instance.prefix,
      'message': instance.message,
      'tags': instance.tags,
    };

const _$NotifyLevelEnumMap = {
  NotifyLevel.noNotify: -1,
  NotifyLevel.low: 0,
  NotifyLevel.message: 1,
  NotifyLevel.privateMessage: 2,
  NotifyLevel.messageWithHighlight: 3,
};
