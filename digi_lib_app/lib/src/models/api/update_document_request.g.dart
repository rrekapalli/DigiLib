// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_document_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateDocumentRequest _$UpdateDocumentRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateDocumentRequest(
      title: json['title'] as String?,
      author: json['author'] as String?,
      renamedName: json['renamed_name'] as String?,
      isbn: json['isbn'] as String?,
      yearPublished: (json['year_published'] as num?)?.toInt(),
      metadataJson: json['metadata_json'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$UpdateDocumentRequestToJson(
        UpdateDocumentRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'author': instance.author,
      'renamed_name': instance.renamedName,
      'isbn': instance.isbn,
      'year_published': instance.yearPublished,
      'metadata_json': instance.metadataJson,
    };
