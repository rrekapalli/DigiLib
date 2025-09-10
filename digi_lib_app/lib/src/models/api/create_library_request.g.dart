// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_library_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateLibraryRequest _$CreateLibraryRequestFromJson(
        Map<String, dynamic> json) =>
    CreateLibraryRequest(
      name: json['name'] as String,
      type: $enumDecode(_$LibraryTypeEnumMap, json['type']),
      config: json['config'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CreateLibraryRequestToJson(
        CreateLibraryRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': _$LibraryTypeEnumMap[instance.type]!,
      'config': instance.config,
    };

const _$LibraryTypeEnumMap = {
  LibraryType.local: 'local',
  LibraryType.gdrive: 'gdrive',
  LibraryType.onedrive: 'onedrive',
  LibraryType.s3: 's3',
};
