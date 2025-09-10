import 'package:json_annotation/json_annotation.dart';
import '../entities/document.dart';
import 'pagination.dart';

part 'search_response.g.dart';

@JsonSerializable()
class SearchHighlight {
  @JsonKey(name: 'page_number')
  final int pageNumber;
  final String text;
  final String context;

  const SearchHighlight({
    required this.pageNumber,
    required this.text,
    required this.context,
  });

  factory SearchHighlight.fromJson(Map<String, dynamic> json) => _$SearchHighlightFromJson(json);
  Map<String, dynamic> toJson() => _$SearchHighlightToJson(this);

  SearchHighlight copyWith({
    int? pageNumber,
    String? text,
    String? context,
  }) {
    return SearchHighlight(
      pageNumber: pageNumber ?? this.pageNumber,
      text: text ?? this.text,
      context: context ?? this.context,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchHighlight &&
        other.pageNumber == pageNumber &&
        other.text == text &&
        other.context == context;
  }

  @override
  int get hashCode {
    return Object.hash(
      pageNumber,
      text,
      context,
    );
  }

  @override
  String toString() {
    return 'SearchHighlight(pageNumber: $pageNumber, text: $text, context: $context)';
  }
}

@JsonSerializable()
class SearchResult {
  final Document document;
  final List<SearchHighlight> highlights;

  const SearchResult({
    required this.document,
    required this.highlights,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => _$SearchResultFromJson(json);
  Map<String, dynamic> toJson() => _$SearchResultToJson(this);

  SearchResult copyWith({
    Document? document,
    List<SearchHighlight>? highlights,
  }) {
    return SearchResult(
      document: document ?? this.document,
      highlights: highlights ?? this.highlights,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResult &&
        other.document == document &&
        other.highlights == highlights;
  }

  @override
  int get hashCode {
    return Object.hash(
      document,
      highlights,
    );
  }

  @override
  String toString() {
    return 'SearchResult(document: $document, highlights: $highlights)';
  }
}

@JsonSerializable()
class SearchResponse {
  final List<SearchResult> results;
  final Pagination pagination;

  const SearchResponse({
    required this.results,
    required this.pagination,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) => _$SearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SearchResponseToJson(this);

  SearchResponse copyWith({
    List<SearchResult>? results,
    Pagination? pagination,
  }) {
    return SearchResponse(
      results: results ?? this.results,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResponse &&
        other.results == results &&
        other.pagination == pagination;
  }

  @override
  int get hashCode {
    return Object.hash(
      results,
      pagination,
    );
  }

  @override
  String toString() {
    return 'SearchResponse(results: $results, pagination: $pagination)';
  }
}