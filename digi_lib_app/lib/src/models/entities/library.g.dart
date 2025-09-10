// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Library _$LibraryFromJson(Map<String, dynamic> json) => Library(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String?,
      name: json['name'] as String,
      type: $enumDecode(_$LibraryTypeEnumMap, json['type']),
      config: json['config'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$LibraryToJson(Library instance) => <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'name': instance.name,
      'type': _$LibraryTypeEnumMap[instance.type]!,
      'config': instance.config,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$LibraryTypeEnumMap = {
  LibraryType.local: 'local',
  LibraryType.gdrive: 'gdrive',
  LibraryType.onedrive: 'onedrive',
  LibraryType.s3: 's3',
};
