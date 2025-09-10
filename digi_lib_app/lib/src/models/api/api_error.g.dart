// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiError _$ApiErrorFromJson(Map<String, dynamic> json) => ApiError(
      message: json['message'] as String,
      code: json['code'] as String?,
      status: (json['status'] as num?)?.toInt(),
      details: json['details'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$ApiErrorToJson(ApiError instance) => <String, dynamic>{
      'message': instance.message,
      'code': instance.code,
      'status': instance.status,
      'details': instance.details,
      'timestamp': instance.timestamp.toIso8601String(),
    };
