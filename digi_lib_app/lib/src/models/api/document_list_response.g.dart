// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentListResponse _$DocumentListResponseFromJson(
        Map<String, dynamic> json) =>
    DocumentListResponse(
      documents: (json['documents'] as List<dynamic>)
          .map((e) => Document.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DocumentListResponseToJson(
        DocumentListResponse instance) =>
    <String, dynamic>{
      'documents': instance.documents,
      'pagination': instance.pagination,
    };
