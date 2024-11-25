// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nick_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NickGroup _$NickGroupFromJson(Map<String, dynamic> json) => NickGroup(
      id: (json['id'] as num).toInt(),
      parentGroupId: (json['parent_group_id'] as num).toInt(),
      name: json['name'] as String,
      colorName: json['color_name'] as String,
      color: json['color'] as String,
      visible: json['visible'] as bool,
      groups: json['groups'] as List<dynamic>,
      nicks: (json['nicks'] as List<dynamic>)
          .map((e) => Nick.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$NickGroupToJson(NickGroup instance) => <String, dynamic>{
      'id': instance.id,
      'parent_group_id': instance.parentGroupId,
      'name': instance.name,
      'color_name': instance.colorName,
      'color': instance.color,
      'visible': instance.visible,
      'groups': instance.groups,
      'nicks': instance.nicks,
    };
