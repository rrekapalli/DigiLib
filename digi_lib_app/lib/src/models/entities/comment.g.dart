// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
      id: json['id'] as String,
      docId: json['doc_id'] as String,
      userId: json['user_id'] as String?,
      pageNumber: (json['page_number'] as num?)?.toInt(),
      anchor: json['anchor'] as Map<String, dynamic>?,
      content: json['content'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
      'id': instance.id,
      'doc_id': instance.docId,
      'user_id': instance.userId,
      'page_number': instance.pageNumber,
      'anchor': instance.anchor,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
    };
