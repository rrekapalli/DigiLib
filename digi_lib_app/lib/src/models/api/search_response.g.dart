// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchHighlight _$SearchHighlightFromJson(Map<String, dynamic> json) =>
    SearchHighlight(
      pageNumber: (json['page_number'] as num).toInt(),
      text: json['text'] as String,
      context: json['context'] as String,
    );

Map<String, dynamic> _$SearchHighlightToJson(SearchHighlight instance) =>
    <String, dynamic>{
      'page_number': instance.pageNumber,
      'text': instance.text,
      'context': instance.context,
    };

SearchResult _$SearchResultFromJson(Map<String, dynamic> json) => SearchResult(
      document: Document.fromJson(json['document'] as Map<String, dynamic>),
      highlights: (json['highlights'] as List<dynamic>)
          .map((e) => SearchHighlight.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SearchResultToJson(SearchResult instance) =>
    <String, dynamic>{
      'document': instance.document,
      'highlights': instance.highlights,
    };

SearchResponse _$SearchResponseFromJson(Map<String, dynamic> json) =>
    SearchResponse(
      results: (json['results'] as List<dynamic>)
          .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SearchResponseToJson(SearchResponse instance) =>
    <String, dynamic>{
      'results': instance.results,
      'pagination': instance.pagination,
    };
