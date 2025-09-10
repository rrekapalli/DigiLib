// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Page _$PageFromJson(Map<String, dynamic> json) => Page(
      id: json['id'] as String,
      docId: json['doc_id'] as String,
      pageNumber: (json['page_number'] as num).toInt(),
      textContent: json['text_content'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PageToJson(Page instance) => <String, dynamic>{
      'id': instance.id,
      'doc_id': instance.docId,
      'page_number': instance.pageNumber,
      'text_content': instance.textContent,
      'thumbnail_url': instance.thumbnailUrl,
      'created_at': instance.createdAt.toIso8601String(),
    };
