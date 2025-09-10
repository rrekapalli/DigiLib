// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_comment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCommentRequest _$CreateCommentRequestFromJson(
        Map<String, dynamic> json) =>
    CreateCommentRequest(
      pageNumber: (json['page_number'] as num).toInt(),
      anchor: json['anchor'] as Map<String, dynamic>?,
      content: json['content'] as String,
    );

Map<String, dynamic> _$CreateCommentRequestToJson(
        CreateCommentRequest instance) =>
    <String, dynamic>{
      'page_number': instance.pageNumber,
      'anchor': instance.anchor,
      'content': instance.content,
    };
