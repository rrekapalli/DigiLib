// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_bookmark_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateBookmarkRequest _$CreateBookmarkRequestFromJson(
        Map<String, dynamic> json) =>
    CreateBookmarkRequest(
      pageNumber: (json['page_number'] as num).toInt(),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$CreateBookmarkRequestToJson(
        CreateBookmarkRequest instance) =>
    <String, dynamic>{
      'page_number': instance.pageNumber,
      'note': instance.note,
    };
