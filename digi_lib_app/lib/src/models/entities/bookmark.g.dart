// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Bookmark _$BookmarkFromJson(Map<String, dynamic> json) => Bookmark(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      docId: json['doc_id'] as String,
      pageNumber: (json['page_number'] as num?)?.toInt(),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$BookmarkToJson(Bookmark instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'doc_id': instance.docId,
      'page_number': instance.pageNumber,
      'note': instance.note,
      'created_at': instance.createdAt.toIso8601String(),
    };
