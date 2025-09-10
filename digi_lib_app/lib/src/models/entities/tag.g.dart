// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tag _$TagFromJson(Map<String, dynamic> json) => Tag(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String?,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TagToJson(Tag instance) => <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'name': instance.name,
      'created_at': instance.createdAt.toIso8601String(),
    };

DocumentTag _$DocumentTagFromJson(Map<String, dynamic> json) => DocumentTag(
      id: json['id'] as String,
      docId: json['doc_id'] as String,
      tagId: json['tag_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$DocumentTagToJson(DocumentTag instance) =>
    <String, dynamic>{
      'id': instance.id,
      'doc_id': instance.docId,
      'tag_id': instance.tagId,
      'created_at': instance.createdAt.toIso8601String(),
    };
