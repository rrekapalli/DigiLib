// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_search.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavedSearch _$SavedSearchFromJson(Map<String, dynamic> json) => SavedSearch(
      id: json['id'] as String,
      name: json['name'] as String,
      query: json['query'] as String,
      filters: json['filters'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] == null
          ? null
          : DateTime.parse(json['lastUsedAt'] as String),
      useCount: (json['useCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SavedSearchToJson(SavedSearch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'query': instance.query,
      'filters': instance.filters,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastUsedAt': instance.lastUsedAt?.toIso8601String(),
      'useCount': instance.useCount,
    };

SearchAnalytics _$SearchAnalyticsFromJson(Map<String, dynamic> json) =>
    SearchAnalytics(
      query: json['query'] as String,
      searchCount: (json['searchCount'] as num).toInt(),
      firstSearched: DateTime.parse(json['firstSearched'] as String),
      lastSearched: DateTime.parse(json['lastSearched'] as String),
      resultCount: (json['resultCount'] as num).toInt(),
      avgResultCount: (json['avgResultCount'] as num).toDouble(),
    );

Map<String, dynamic> _$SearchAnalyticsToJson(SearchAnalytics instance) =>
    <String, dynamic>{
      'query': instance.query,
      'searchCount': instance.searchCount,
      'firstSearched': instance.firstSearched.toIso8601String(),
      'lastSearched': instance.lastSearched.toIso8601String(),
      'resultCount': instance.resultCount,
      'avgResultCount': instance.avgResultCount,
    };
