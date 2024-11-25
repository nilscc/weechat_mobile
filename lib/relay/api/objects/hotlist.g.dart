// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hotlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Hotlist _$HotlistFromJson(Map<String, dynamic> json) => Hotlist(
      priority: $enumDecode(_$PriorityEnumMap, json['priority']),
      date: DateTime.parse(json['date'] as String),
      bufferId: (json['buffer_id'] as num).toInt(),
      count: (json['count'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$HotlistToJson(Hotlist instance) => <String, dynamic>{
      'priority': _$PriorityEnumMap[instance.priority]!,
      'date': instance.date.toIso8601String(),
      'buffer_id': instance.bufferId,
      'count': instance.count,
    };

const _$PriorityEnumMap = {
  Priority.low: 0,
  Priority.message: 1,
  Priority.private: 2,
  Priority.highlight: 3,
};
