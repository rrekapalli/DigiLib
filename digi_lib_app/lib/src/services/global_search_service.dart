import 'dart:async';
import '../models/api/search_response.dart';
import '../models/api/pagination.dart';
import '../models/entities/document.dart';
import '../network/connectivity_service.dart';
import '../database/fts_helper.dart';
import 'search_api_service.dart';
import 'local_search_service.dart';

/// Global search service that combines API and local search
class GlobalSearchService {
  final SearchApiService _searchApiService;
  final LocalSearchService _localSearchService;
  final ConnectivityService _connectivityService;

  GlobalSearchService(
    this._searchApiService,
    this._localSearchService,
    this._connectivityService,
  );

  /// Search documents globally with fallback to local search
  Future<CombinedSearchResults> searchCombined(
    String query, {
    String? libraryId,
    List<String>? tags,
    int page = 1,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      return CombinedSearchResults.empty();
    }

    // Check connectivity
    final isOnline = _connectivityService.hasConnectivity();
    
    if (isOnline) {
      try {
        // Try global search first
        final globalResults = await searchGlobal(
          query,
          libraryId: libraryId,
          tags: tags,
          page: page,
          limit: limit,
        );

        // Get local results for comparison/deduplication
        final localResults = await _searchLocal(
          query,
          libraryId: libraryId,
          tags: tags,
          page: page,
          limit: limit,
        );

        // Combine and deduplicate results
        final combinedResults = _combineAndDeduplicateResults(
          globalResults,
          localResults,
          query,
        );

        return CombinedSearchResults(
          query: query,
          results: combinedResults,
          source: SearchResultSource.global,
          pagination: globalResults.pagination,
          hasLocalFallback: localResults.isNotEmpty,
        );
      } catch (e) {
        // Fallback to local search on API failure
        return await _searchLocalWithFallback(
          query,
          libraryId: libraryId,
          tags: tags,
          page: page,
          limit: limit,
          error: e,
        );
      }
    } else {
      // Offline - use local search only
      return await _searchLocalWithFallback(
        query,
        libraryId: libraryId,
        tags: tags,
        page: page,
        limit: limit,
      );
    }
  }

  /// Search documents globally using backend API
  Future<SearchResponse> searchGlobal(
    String query, {
    String? libraryId,
    List<String>? tags,
    int page = 1,
    int limit = 20,
  }) async {
    return await _searchApiService.searchGlobal(
      query,
      libraryId: libraryId,
      tags: tags,
      page: page,
      limit: limit,
    );
  }

  /// Search within a specific document globally
  Future<SearchResponse> searchInDocumentGlobal(
    String documentId,
    String query, {
    int page = 1,
    int limit = 50,
  }) async {
    final isOnline = _connectivityService.hasConnectivity();
    
    if (isOnline) {
      try {
        return await _searchApiService.searchInDocument(
          documentId,
          query,
          page: page,
          limit: limit,
        );
      } catch (e) {
        // Fallback to local search
        final localMatches = await _localSearchService.searchInDocument(
          documentId,
          query,
          limit: limit,
        );
        
        // Convert local matches to SearchResponse format
        return _convertLocalMatchesToSearchResponse(localMatches, query);
      }
    } else {
      // Offline - use local search
      final localMatches = await _localSearchService.searchInDocument(
        documentId,
        query,
        limit: limit,
      );
      
      return _convertLocalMatchesToSearchResponse(localMatches, query);
    }
  }

  /// Get search suggestions with fallback
  Future<List<String>> getSearchSuggestions(
    String partialQuery, {
    int limit = 10,
  }) async {
    if (partialQuery.trim().isEmpty) return [];

    final isOnline = _connectivityService.hasConnectivity();
    
    if (isOnline) {
      try {
        // Try to get suggestions from API
        final apiSuggestions = await _searchApiService.getSearchSuggestions(
          partialQuery,
          limit: limit,
        );

        // Get local suggestions
        final localSuggestions = await _localSearchService.getSearchSuggestions(
          partialQuery,
          limit: limit,
        );

        // Combine and deduplicate suggestions
        final combinedSuggestions = <String>{};
        combinedSuggestions.addAll(apiSuggestions);
        combinedSuggestions.addAll(localSuggestions);

        return combinedSuggestions.take(limit).toList();
      } catch (e) {
        // Fallback to local suggestions
        return await _localSearchService.getSearchSuggestions(
          partialQuery,
          limit: limit,
        );
      }
    } else {
      // Offline - use local suggestions only
      return await _localSearchService.getSearchSuggestions(
        partialQuery,
        limit: limit,
      );
    }
  }

  /// Search locally with proper error handling
  Future<LocalSearchResults> _searchLocal(
    String query, {
    String? libraryId,
    List<String>? tags,
    int page = 1,
    int limit = 20,
  }) async {
    final filters = LocalSearchFilters(
      libraryIds: libraryId != null ? [libraryId] : null,
      tagFilters: tags,
    );

    return await _localSearchService.searchDocuments(
      query,
      page: page,
      limit: limit,
      filters: filters,
    );
  }

  /// Search locally with fallback handling
  Future<CombinedSearchResults> _searchLocalWithFallback(
    String query, {
    String? libraryId,
    List<String>? tags,
    int page = 1,
    int limit = 20,
    Object? error,
  }) async {
    final localResults = await _searchLocal(
      query,
      libraryId: libraryId,
      tags: tags,
      page: page,
      limit: limit,
    );

    return CombinedSearchResults(
      query: query,
      results: _convertLocalToGlobalResults(localResults.results),
      source: SearchResultSource.local,
      pagination: _convertLocalPagination(localResults.pagination),
      hasLocalFallback: false,
      fallbackError: error,
    );
  }

  /// Combine and deduplicate search results from global and local sources
  List<SearchResult> _combineAndDeduplicateResults(
    SearchResponse globalResults,
    LocalSearchResults localResults,
    String query,
  ) {
    final combinedResults = <String, SearchResult>{};
    
    // Add global results first (they have priority)
    for (final result in globalResults.results) {
      combinedResults[result.document.id] = result;
    }

    // Add local results that aren't already present
    for (final localResult in localResults.results) {
      if (!combinedResults.containsKey(localResult.docId)) {
        // Convert local result to global format
        final globalResult = _convertLocalToGlobalResult(localResult, query);
        if (globalResult != null) {
          combinedResults[localResult.docId] = globalResult;
        }
      }
    }

    return combinedResults.values.toList();
  }

  /// Convert local search results to global format
  List<SearchResult> _convertLocalToGlobalResults(List<FTSSearchResult> localResults) {
    return localResults
        .map((local) => _convertLocalToGlobalResult(local, ''))
        .where((result) => result != null)
        .cast<SearchResult>()
        .toList();
  }

  /// Convert single local result to global format
  SearchResult? _convertLocalToGlobalResult(FTSSearchResult localResult, String query) {
    // This would need to fetch the full document from local database
    // For now, we'll create a minimal SearchResult
    // In a real implementation, you'd fetch the Document entity
    
    try {
      // Create highlights from local snippets
      final highlights = <SearchHighlight>[];
      
      if (localResult.contentSnippet != null) {
        highlights.add(SearchHighlight(
          pageNumber: 1, // Default page number
          text: query,
          context: localResult.contentSnippet!,
        ));
      }

      // Note: This is a simplified conversion
      // In practice, you'd need to fetch the full Document entity from local database
      return SearchResult(
        document: _createMinimalDocument(localResult),
        highlights: highlights,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create minimal document from local search result
  /// This is a placeholder - in practice you'd fetch from local database
  Document _createMinimalDocument(FTSSearchResult localResult) {
    return Document(
      id: localResult.docId,
      libraryId: localResult.libraryId ?? '',
      title: localResult.title,
      author: localResult.author,
      filename: localResult.filename,
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
      imageUrl: localResult.imageUrl,
      amazonUrl: null,
      reviewUrl: null,
      metadataJson: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Convert local pagination to API pagination format
  Pagination _convertLocalPagination(SearchPagination localPagination) {
    return Pagination(
      page: localPagination.page,
      limit: localPagination.limit,
      total: localPagination.totalResults,
      totalPages: localPagination.totalPages,
    );
  }

  /// Convert local document matches to SearchResponse
  SearchResponse _convertLocalMatchesToSearchResponse(
    List<DocumentPageMatch> matches,
    String query,
  ) {
    final highlights = matches.map((match) => SearchHighlight(
      pageNumber: match.pageNumber,
      text: query,
      context: match.snippet ?? match.textContent ?? '',
    )).toList();

    // Group highlights by document (assuming all matches are from same document)
    final results = <SearchResult>[];
    if (matches.isNotEmpty) {
      // Create a minimal document for the matches
      // In practice, you'd fetch the actual document from local database
      final document = Document(
        id: 'local-doc', // This should be the actual document ID
        libraryId: '',
        title: 'Document',
        author: null,
        filename: null,
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
        imageUrl: null,
        amazonUrl: null,
        reviewUrl: null,
        metadataJson: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      results.add(SearchResult(
        document: document,
        highlights: highlights,
      ));
    }

    return SearchResponse(
      results: results,
      pagination: Pagination(
        page: 1,
        limit: matches.length,
        total: matches.length,
        totalPages: 1,
      ),
    );
  }
}

/// Combined search results from global and local sources
class CombinedSearchResults {
  final String query;
  final List<SearchResult> results;
  final SearchResultSource source;
  final Pagination pagination;
  final bool hasLocalFallback;
  final Object? fallbackError;

  CombinedSearchResults({
    required this.query,
    required this.results,
    required this.source,
    required this.pagination,
    this.hasLocalFallback = false,
    this.fallbackError,
  });

  factory CombinedSearchResults.empty() {
    return CombinedSearchResults(
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
  bool get hadFallback => fallbackError != null;
}

/// Source of search results
enum SearchResultSource {
  global,
  local,
  combined,
}

/// Global search exception
class GlobalSearchException implements Exception {
  final String message;
  final Object? cause;

  GlobalSearchException(this.message, [this.cause]);

  @override
  String toString() => 'GlobalSearchException: $message';
}