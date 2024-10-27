// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nick.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Nick _$NickFromJson(Map<String, dynamic> json) => Nick(
      id: (json['id'] as num).toInt(),
      parentGroupId: (json['parent_group_id'] as num).toInt(),
      prefix: json['prefix'] as String,
      prefixColorName: json['prefix_color_name'] as String,
      prefixColor: json['prefix_color'] as String,
      name: json['name'] as String,
      colorName: json['color_name'] as String,
      color: json['color'] as String,
      visible: json['visible'] as bool,
    );

Map<String, dynamic> _$NickToJson(Nick instance) => <String, dynamic>{
      'id': instance.id,
      'parent_group_id': instance.parentGroupId,
      'prefix': instance.prefix,
      'prefix_color_name': instance.prefixColorName,
      'prefix_color': instance.prefixColor,
      'name': instance.name,
      'color_name': instance.colorName,
      'color': instance.color,
      'visible': instance.visible,
    };
