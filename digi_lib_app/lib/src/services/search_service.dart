import 'dart:async';
import '../models/api/search_response.dart';
import '../models/api/pagination.dart';
import '../models/entities/document.dart';
import '../database/fts_helper.dart';
import 'local_search_service.dart';
import 'global_search_service.dart';

/// Main search service that provides unified search interface
class SearchService {
  final LocalSearchService _localSearchService;
  final GlobalSearchService _globalSearchService;

  SearchService(
    this._localSearchService,
    this._globalSearchService,
  );

  /// Search documents with automatic fallback between global and local
  Future<UnifiedSearchResults> search(
    String query, {
    SearchFilters? filters,
    int page = 1,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      return UnifiedSearchResults.empty();
    }

    try {
      // Use global search service which handles fallback internally
      final combinedResults = await _globalSearchService.searchCombined(
        query,
        libraryId: filters?.libraryId,
        tags: filters?.tags,
        page: page,
        limit: limit,
      );

      return UnifiedSearchResults(
        query: query,
        results: combinedResults.results,
        source: combinedResults.source,
        pagination: combinedResults.pagination,
        filters: filters,
        hasLocalFallback: combinedResults.hasLocalFallback,
        error: combinedResults.fallbackError,
      );
    } catch (e) {
      // Final fallback to local search only
      final localResults = await _localSearchService.searchDocuments(
        query,
        page: page,
        limit: limit,
        filters: _convertToLocalFilters(filters),
      );

      return UnifiedSearchResults(
        query: query,
        results: _convertLocalToSearchResults(localResults.results),
        source: SearchResultSource.local,
        pagination: _convertLocalPagination(localResults.pagination),
        filters: filters,
        hasLocalFallback: false,
        error: e,
      );
    }
  }

  /// Search within a specific document
  Future<DocumentSearchResults> searchInDocument(
    String documentId,
    String query, {
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) {
      return DocumentSearchResults.empty(documentId);
    }

    try {
      // Try global search first
      final globalResults = await _globalSearchService.searchInDocumentGlobal(
        documentId,
        query,
        limit: limit,
      );

      return DocumentSearchResults(
        documentId: documentId,
        query: query,
        highlights: globalResults.results.isNotEmpty 
            ? globalResults.results.first.highlights 
            : [],
        source: SearchResultSource.global,
      );
    } catch (e) {
      // Fallback to local search
      final localMatches = await _localSearchService.searchInDocument(
        documentId,
        query,
        limit: limit,
      );

      final highlights = localMatches.map((match) => SearchHighlight(
        pageNumber: match.pageNumber,
        text: query,
        context: match.snippet ?? match.textContent ?? '',
      )).toList();

      return DocumentSearchResults(
        documentId: documentId,
        query: query,
        highlights: highlights,
        source: SearchResultSource.local,
        error: e,
      );
    }
  }

  /// Get search suggestions
  Future<List<String>> getSearchSuggestions(
    String partialQuery, {
    int limit = 10,
  }) async {
    return await _globalSearchService.getSearchSuggestions(
      partialQuery,
      limit: limit,
    );
  }

  /// Get search history
  Future<List<String>> getSearchHistory({int limit = 20}) async {
    return await _localSearchService.getSearchHistory(limit: limit);
  }

  /// Save search to history
  Future<void> saveSearchToHistory(String query) async {
    await _localSearchService.saveSearchToHistory(query);
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    await _localSearchService.clearSearchHistory();
  }

  /// Check if search index is ready
  Future<bool> isSearchIndexReady() async {
    return await _localSearchService.isSearchIndexReady();
  }

  /// Rebuild search index
  Future<void> rebuildSearchIndex() async {
    await _localSearchService.rebuildSearchIndex();
  }

  /// Get search index statistics
  Future<SearchIndexStats> getIndexStatistics() async {
    return await _localSearchService.getIndexStatistics();
  }

  /// Index document content for search
  Future<void> indexDocumentContent(String documentId, String content) async {
    await _localSearchService.indexDocumentContent(documentId, content);
  }

  /// Index document tags for search
  Future<void> indexDocumentTags(String documentId, List<String> tags) async {
    await _localSearchService.indexDocumentTags(documentId, tags);
  }

  /// Convert search filters to local search filters
  LocalSearchFilters? _convertToLocalFilters(SearchFilters? filters) {
    if (filters == null) return null;
    
    return LocalSearchFilters(
      libraryIds: filters.libraryId != null ? [filters.libraryId!] : null,
      tagFilters: filters.tags,
      dateFrom: filters.dateFrom,
      dateTo: filters.dateTo,
      authors: filters.authors,
      fileTypes: filters.fileTypes,
    );
  }

  /// Convert local search results to SearchResult format
  List<SearchResult> _convertLocalToSearchResults(List<FTSSearchResult> localResults) {
    // This is a simplified conversion
    // In practice, you'd need to fetch full Document entities from local database
    return localResults.map((local) {
      // Create minimal document
      final document = Document(
        id: local.docId,
        libraryId: local.libraryId ?? '',
        title: local.title,
        author: local.author,
        filename: local.filename,
        relativePath: null,
        fullPath: null,
        extension: null,
        renamedName: null,
        isbn: null,
        yearPublished: null,
        status: null,
        cloudId: null,
        sha256: null,
        sizeBytes: null,
        pageCount: null,
        format: null,
        imageUrl: local.imageUrl,
        amazonUrl: null,
        reviewUrl: null,
        metadataJson: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create highlights from snippets
      final highlights = <SearchHighlight>[];
      if (local.contentSnippet != null) {
        highlights.add(SearchHighlight(
          pageNumber: 1,
          text: '',
          context: local.contentSnippet!,
        ));
      }

      return SearchResult(
        document: document,
        highlights: highlights,
      );
    }).toList();
  }

  /// Convert local pagination to API pagination
  Pagination _convertLocalPagination(SearchPagination localPagination) {
    return Pagination(
      page: localPagination.page,
      limit: localPagination.limit,
      total: localPagination.totalResults,
      totalPages: localPagination.totalPages,
    );
  }
}

/// Unified search results combining global and local sources
class UnifiedSearchResults {
  final String query;
  final List<SearchResult> results;
  final SearchResultSource source;
  final Pagination pagination;
  final SearchFilters? filters;
  final bool hasLocalFallback;
  final Object? error;

  UnifiedSearchResults({
    required this.query,
    required this.results,
    required this.source,
    required this.pagination,
    this.filters,
    this.hasLocalFallback = false,
    this.error,
  });

  factory UnifiedSearchResults.empty() {
    return UnifiedSearchResults(
      query: '',
      results: [],
      source: SearchResultSource.local,
      pagination: Pagination(page: 1, limit: 20, total: 0, totalPages: 0),
    );
  }

  bool get isEmpty => results.isEmpty;
  bool get isNotEmpty => results.isNotEmpty;
  int get length => results.length;
  bool get isFromGlobalSearch => source == SearchResultSource.global;
  bool get isFromLocalSearch => source == SearchResultSource.local;
  bool get hadError => error != null;
}

/// Document-specific search results
class DocumentSearchResults {
  final String documentId;
  final String query;
  final List<SearchHighlight> highlights;
  final SearchResultSource source;
  final Object? error;

  DocumentSearchResults({
    required this.documentId,
    required this.query,
    required this.highlights,
    required this.source,
    this.error,
  });

  factory DocumentSearchResults.empty(String documentId) {
    return DocumentSearchResults(
      documentId: documentId,
      query: '',
      highlights: [],
      source: SearchResultSource.local,
    );
  }

  bool get isEmpty => highlights.isEmpty;
  bool get isNotEmpty => highlights.isNotEmpty;
  int get length => highlights.length;
  bool get hadError => error != null;
}

/// Search filters for unified search
class SearchFilters {
  final String? libraryId;
  final List<String>? tags;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final List<String>? authors;
  final List<String>? fileTypes;

  SearchFilters({
    this.libraryId,
    this.tags,
    this.dateFrom,
    this.dateTo,
    this.authors,
    this.fileTypes,
  });

  Map<String, dynamic> toMap() {
    return {
      'library_id': libraryId,
      'tags': tags,
      'date_from': dateFrom?.toIso8601String(),
      'date_to': dateTo?.toIso8601String(),
      'authors': authors,
      'file_types': fileTypes,
    };
  }

  SearchFilters copyWith({
    String? libraryId,
    List<String>? tags,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? authors,
    List<String>? fileTypes,
  }) {
    return SearchFilters(
      libraryId: libraryId ?? this.libraryId,
      tags: tags ?? this.tags,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      authors: authors ?? this.authors,
      fileTypes: fileTypes ?? this.fileTypes,
    );
  }
}

/// Search service exception
class SearchServiceException implements Exception {
  final String message;
  final Object? cause;

  SearchServiceException(this.message, [this.cause]);

  @override
  String toString() => 'SearchServiceException: $message';
}