import 'package:json_annotation/json_annotation.dart';

part 'saved_search.g.dart';

@JsonSerializable()
class SavedSearch {
  final String id;
  final String name;
  final String query;
  final Map<String, dynamic>? filters;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int useCount;

  const SavedSearch({
    required this.id,
    required this.name,
    required this.query,
    this.filters,
    required this.createdAt,
    this.lastUsedAt,
    this.useCount = 0,
  });

  factory SavedSearch.fromJson(Map<String, dynamic> json) => _$SavedSearchFromJson(json);
  Map<String, dynamic> toJson() => _$SavedSearchToJson(this);

  SavedSearch copyWith({
    String? id,
    String? name,
    String? query,
    Map<String, dynamic>? filters,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? useCount,
  }) {
    return SavedSearch(
      id: id ?? this.id,
      name: name ?? this.name,
      query: query ?? this.query,
      filters: filters ?? this.filters,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      useCount: useCount ?? this.useCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedSearch &&
        other.id == id &&
        other.name == name &&
        other.query == query &&
        other.filters == filters &&
        other.createdAt == createdAt &&
        other.lastUsedAt == lastUsedAt &&
        other.useCount == useCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      query,
      filters,
      createdAt,
      lastUsedAt,
      useCount,
    );
  }

  @override
  String toString() {
    return 'SavedSearch(id: $id, name: $name, query: $query, filters: $filters, createdAt: $createdAt, lastUsedAt: $lastUsedAt, useCount: $useCount)';
  }
}

@JsonSerializable()
class SearchAnalytics {
  final String query;
  final int searchCount;
  final DateTime firstSearched;
  final DateTime lastSearched;
  final int resultCount;
  final double avgResultCount;

  const SearchAnalytics({
    required this.query,
    required this.searchCount,
    required this.firstSearched,
    required this.lastSearched,
    required this.resultCount,
    required this.avgResultCount,
  });

  factory SearchAnalytics.fromJson(Map<String, dynamic> json) => _$SearchAnalyticsFromJson(json);
  Map<String, dynamic> toJson() => _$SearchAnalyticsToJson(this);

  SearchAnalytics copyWith({
    String? query,
    int? searchCount,
    DateTime? firstSearched,
    DateTime? lastSearched,
    int? resultCount,
    double? avgResultCount,
  }) {
    return SearchAnalytics(
      query: query ?? this.query,
      searchCount: searchCount ?? this.searchCount,
      firstSearched: firstSearched ?? this.firstSearched,
      lastSearched: lastSearched ?? this.lastSearched,
      resultCount: resultCount ?? this.resultCount,
      avgResultCount: avgResultCount ?? this.avgResultCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchAnalytics &&
        other.query == query &&
        other.searchCount == searchCount &&
        other.firstSearched == firstSearched &&
        other.lastSearched == lastSearched &&
        other.resultCount == resultCount &&
        other.avgResultCount == avgResultCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      query,
      searchCount,
      firstSearched,
      lastSearched,
      resultCount,
      avgResultCount,
    );
  }

  @override
  String toString() {
    return 'SearchAnalytics(query: $query, searchCount: $searchCount, firstSearched: $firstSearched, lastSearched: $lastSearched, resultCount: $resultCount, avgResultCount: $avgResultCount)';
  }
}