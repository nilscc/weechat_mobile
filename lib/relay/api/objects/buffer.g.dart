// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buffer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Buffer _$BufferFromJson(Map<String, dynamic> json) => Buffer(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      shortName: json['short_name'] as String,
      number: (json['number'] as num).toInt(),
      type: $enumDecode(_$BufferTypeEnumMap, json['type']),
      hidden: json['hidden'] as bool,
      title: json['title'] as String,
      modes: json['modes'] as String,
      inputPrompt: json['input_prompt'] as String,
      input: json['input'] as String,
      inputPosition: (json['input_position'] as num).toInt(),
      inputMultiline: json['input_multiline'] as bool,
      nicklist: json['nicklist'] as bool,
      nicklistCaseSensitive: json['nicklist_case_sensitive'] as bool,
      timeDisplayed: json['time_displayed'] as bool,
      localVariables: json['local_variables'] as Map<String, dynamic>,
      keys: (json['keys'] as List<dynamic>)
          .map((e) => Map<String, String>.from(e as Map))
          .toList(),
    );

Map<String, dynamic> _$BufferToJson(Buffer instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'short_name': instance.shortName,
      'number': instance.number,
      'type': _$BufferTypeEnumMap[instance.type]!,
      'hidden': instance.hidden,
      'title': instance.title,
      'modes': instance.modes,
      'input_prompt': instance.inputPrompt,
      'input': instance.input,
      'input_position': instance.inputPosition,
      'input_multiline': instance.inputMultiline,
      'nicklist': instance.nicklist,
      'nicklist_case_sensitive': instance.nicklistCaseSensitive,
      'time_displayed': instance.timeDisplayed,
      'local_variables': instance.localVariables,
      'keys': instance.keys,
    };

const _$BufferTypeEnumMap = {
  BufferType.formatted: 'formatted',
  BufferType.free: 'free',
};
