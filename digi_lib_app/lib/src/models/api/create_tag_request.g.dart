// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_tag_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateTagRequest _$CreateTagRequestFromJson(Map<String, dynamic> json) =>
    CreateTagRequest(
      name: json['name'] as String,
    );

Map<String, dynamic> _$CreateTagRequestToJson(CreateTagRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
    };

AddTagToDocumentRequest _$AddTagToDocumentRequestFromJson(
        Map<String, dynamic> json) =>
    AddTagToDocumentRequest(
      tagId: json['tag_id'] as String,
    );

Map<String, dynamic> _$AddTagToDocumentRequestToJson(
        AddTagToDocumentRequest instance) =>
    <String, dynamic>{
      'tag_id': instance.tagId,
    };
