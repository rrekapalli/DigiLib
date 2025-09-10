// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScanJob _$ScanJobFromJson(Map<String, dynamic> json) => ScanJob(
      id: json['id'] as String,
      libraryId: json['library_id'] as String,
      status: json['status'] as String,
      progress: (json['progress'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
    );

Map<String, dynamic> _$ScanJobToJson(ScanJob instance) => <String, dynamic>{
      'id': instance.id,
      'library_id': instance.libraryId,
      'status': instance.status,
      'progress': instance.progress,
      'created_at': instance.createdAt.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
    };
