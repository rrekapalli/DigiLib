// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReadingProgress _$ReadingProgressFromJson(Map<String, dynamic> json) =>
    ReadingProgress(
      userId: json['user_id'] as String,
      docId: json['doc_id'] as String,
      lastPage: (json['last_page'] as num?)?.toInt(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ReadingProgressToJson(ReadingProgress instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'doc_id': instance.docId,
      'last_page': instance.lastPage,
      'updated_at': instance.updatedAt.toIso8601String(),
    };
