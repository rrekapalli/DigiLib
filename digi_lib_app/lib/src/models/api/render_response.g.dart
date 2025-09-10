// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'render_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RenderResponse _$RenderResponseFromJson(Map<String, dynamic> json) =>
    RenderResponse(
      signedUrl: json['signed_url'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );

Map<String, dynamic> _$RenderResponseToJson(RenderResponse instance) =>
    <String, dynamic>{
      'signed_url': instance.signedUrl,
      'expires_at': instance.expiresAt.toIso8601String(),
    };
