import 'package:digi_lib_app/src/database/fts_helper.dart';
import 'package:digi_lib_app/src/database/database_helper.dart';
import 'package:digi_lib_app/src/database/database_constants.dart';

/// Local search service using SQLite FTS5
class LocalSearchService {
  static const int _defaultPageSize = 20;
  static const int _maxPageSize = 100;
  
  /// Search documents locally using FTS5
  Future<LocalSearchResults> searchDocuments(
    String query, {
    int page = 1,
    int limit = _defaultPageSize,
    LocalSearchFilters? filters,
  }) async {
    if (query.trim().isEmpty) {
      return LocalSearchResults.empty();
    }
    
    // Validate and adjust pagination
    final validatedLimit = limit.clamp(1, _maxPageSize);
    final validatedPage = page.clamp(1, 999999);
    final offset = (validatedPage - 1) * validatedLimit;
    
    try {
      // Perform FTS search
      final results = await FTSHelper.searchWithHighlights(
        query,
        limit: validatedLimit,
        offset: offset,
        libraryIds: filters?.libraryIds,
        tagFilters: filters?.tagFilters,
      );
      
      // Get total count for pagination
      final totalCount = await _getSearchResultCount(query, filters);
      
      return LocalSearchResults(
        query: query,
        results: results,
        pagination: SearchPagination(
          page: validatedPage,
          limit: validatedLimit,
          totalResults: totalCount,
        ),
        filters: filters,
      );
    } catch (e) {
      throw LocalSearchException('Failed to search documents: $e');
    }
  }
  
  /// Get search suggestions based on partial input
  Future<List<String>> getSearchSuggestions(
    String partialQuery, {
    int limit = 10,
  }) async {
    if (partialQuery.trim().isEmpty) return [];
    
    try {
      return await FTSHelper.getSuggestions(partialQuery, limit: limit);
    } catch (e) {
      throw LocalSearchException('Failed to get search suggestions: $e');
    }
  }
  
  /// Search within a specific document's content
  Future<List<DocumentPageMatch>> searchInDocument(
    String documentId,
    String query, {
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) return [];
    
    final db = await DatabaseHelper.instance.database;
    
    try {
      final results = await db.rawQuery('''
        SELECT 
          p.page_number,
          p.text_content,
          snippet(pages_fts, 0, '<mark>', '</mark>', '...', 32) as snippet
        FROM pages_fts pf
        INNER JOIN pages p ON pf.page_id = p.id
        WHERE pf.pages_fts MATCH ? AND p.doc_id = ?
        ORDER BY p.page_number
        LIMIT ?
      ''', [query, documentId, limit]);
      
      return results.map((row) => DocumentPageMatch.fromMap(row)).toList();
    } catch (e) {
      // Fallback to simple text search if FTS fails
      return await _fallbackSearchInDocument(documentId, query, limit);
    }
  }
  
  /// Get search history
  Future<List<String>> getSearchHistory({int limit = 20}) async {
    final db = await DatabaseHelper.instance.database;
    
    try {
      final results = await db.rawQuery('''
        SELECT DISTINCT query 
        FROM search_history 
        ORDER BY last_searched DESC 
        LIMIT ?
      ''', [limit]);
      
      return results.map((row) => row['query'] as String).toList();
    } catch (e) {
      // Table might not exist yet
      return [];
    }
  }
  
  /// Save search query to history
  Future<void> saveSearchToHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final db = await DatabaseHelper.instance.database;
    
    try {
      // Create search history table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS search_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          query TEXT UNIQUE NOT NULL,
          search_count INTEGER DEFAULT 1,
          last_searched INTEGER NOT NULL
        )
      ''');
      
      // Insert or update search history
      await db.execute('''
        INSERT OR REPLACE INTO search_history (query, search_count, last_searched)
        VALUES (
          ?, 
          COALESCE((SELECT search_count FROM search_history WHERE query = ?) + 1, 1),
          ?
        )
      ''', [query, query, DatabaseUtils.getCurrentTimestamp()]);
      
      // Keep only the most recent searches
      await db.execute('''
        DELETE FROM search_history 
        WHERE id NOT IN (
          SELECT id FROM search_history 
          ORDER BY last_searched DESC 
          LIMIT 100
        )
      ''');
    } catch (e) {
      // Ignore errors for search history
    }
  }
  
  /// Clear search history
  Future<void> clearSearchHistory() async {
    final db = await DatabaseHelper.instance.database;
    
    try {
      await db.execute('DELETE FROM search_history');
    } catch (e) {
      // Ignore errors
    }
  }
  
  /// Index document content for search
  Future<void> indexDocumentContent(String documentId, String content) async {
    try {
      await FTSHelper.indexDocumentContent(documentId, content);
    } catch (e) {
      throw LocalSearchException('Failed to index document content: $e');
    }
  }
  
  /// Index document tags for search
  Future<void> indexDocumentTags(String documentId, List<String> tags) async {
    try {
      await FTSHelper.indexDocumentTags(documentId, tags);
    } catch (e) {
      throw LocalSearchException('Failed to index document tags: $e');
    }
  }
  
  /// Rebuild the entire search index
  Future<void> rebuildSearchIndex() async {
    try {
      await FTSHelper.rebuildIndex();
    } catch (e) {
      throw LocalSearchException('Failed to rebuild search index: $e');
    }
  }
  
  /// Get search index statistics
  Future<SearchIndexStats> getIndexStatistics() async {
    try {
      final stats = await FTSHelper.getStatistics();
      return SearchIndexStats.fromMap(stats);
    } catch (e) {
      throw LocalSearchException('Failed to get index statistics: $e');
    }
  }
  
  /// Check if search index is properly initialized
  Future<bool> isSearchIndexReady() async {
    try {
      return await FTSHelper.isFTSInitialized();
    } catch (e) {
      return false;
    }
  }
  
  /// Get total count of search results
  Future<int> _getSearchResultCount(String query, LocalSearchFilters? filters) async {
    final db = await DatabaseHelper.instance.database;
    
    String sql = '''
      SELECT COUNT(*) as count
      FROM documents_fts fts
      INNER JOIN documents d ON fts.doc_id = d.id
      WHERE documents_fts MATCH ?
    ''';
    
    List<dynamic> args = [query];
    
    // Add library filter
    if (filters?.libraryIds != null && filters!.libraryIds!.isNotEmpty) {
      final placeholders = List.filled(filters.libraryIds!.length, '?').join(', ');
      sql += ' AND d.library_id IN ($placeholders)';
      args.addAll(filters.libraryIds!);
    }
    
    // Add tag filter
    if (filters?.tagFilters != null && filters!.tagFilters!.isNotEmpty) {
      sql += '''
        AND d.id IN (
          SELECT dt.doc_id 
          FROM document_tags dt 
          INNER JOIN tags t ON dt.tag_id = t.id 
          WHERE t.name IN (${List.filled(filters.tagFilters!.length, '?').join(', ')})
        )
      ''';
      args.addAll(filters.tagFilters!);
    }
    
    final result = await db.rawQuery(sql, args);
    return result.first['count'] as int;
  }
  
  /// Fallback search in document when FTS is not available
  Future<List<DocumentPageMatch>> _fallbackSearchInDocument(
    String documentId,
    String query,
    int limit,
  ) async {
    final db = await DatabaseHelper.instance.database;
    
    final results = await db.rawQuery('''
      SELECT 
        page_number,
        text_content,
        text_content as snippet
      FROM pages
      WHERE doc_id = ? AND text_content LIKE ?
      ORDER BY page_number
      LIMIT ?
    ''', [documentId, '%$query%', limit]);
    
    return results.map((row) => DocumentPageMatch.fromMap(row)).toList();
  }
}

/// Local search results container
class LocalSearchResults {
  final String query;
  final List<FTSSearchResult> results;
  final SearchPagination pagination;
  final LocalSearchFilters? filters;
  
  LocalSearchResults({
    required this.query,
    required this.results,
    required this.pagination,
    this.filters,
  });
  
  factory LocalSearchResults.empty() {
    return LocalSearchResults(
      query: '',
      results: [],
      pagination: SearchPagination(page: 1, limit: 20, totalResults: 0),
    );
  }
  
  bool get isEmpty => results.isEmpty;
  bool get isNotEmpty => results.isNotEmpty;
  int get length => results.length;
}

/// Search filters for local search
class LocalSearchFilters {
  final List<String>? libraryIds;
  final List<String>? tagFilters;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final List<String>? authors;
  final List<String>? fileTypes;
  
  LocalSearchFilters({
    this.libraryIds,
    this.tagFilters,
    this.dateFrom,
    this.dateTo,
    this.authors,
    this.fileTypes,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'library_ids': libraryIds,
      'tag_filters': tagFilters,
      'date_from': dateFrom?.toIso8601String(),
      'date_to': dateTo?.toIso8601String(),
      'authors': authors,
      'file_types': fileTypes,
    };
  }
}

/// Search pagination information
class SearchPagination {
  final int page;
  final int limit;
  final int totalResults;
  final int totalPages;
  
  SearchPagination({
    required this.page,
    required this.limit,
    required this.totalResults,
  }) : totalPages = totalResults > 0 ? ((totalResults - 1) ~/ limit) + 1 : 0;
  
  int get offset => (page - 1) * limit;
  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
  int get startIndex => offset + 1;
  int get endIndex => (offset + limit).clamp(0, totalResults);
}

/// Document page match for in-document search
class DocumentPageMatch {
  final int pageNumber;
  final String? textContent;
  final String? snippet;
  
  DocumentPageMatch({
    required this.pageNumber,
    this.textContent,
    this.snippet,
  });
  
  factory DocumentPageMatch.fromMap(Map<String, dynamic> map) {
    return DocumentPageMatch(
      pageNumber: map['page_number'] as int,
      textContent: map['text_content'] as String?,
      snippet: map['snippet'] as String?,
    );
  }
}

/// Search index statistics
class SearchIndexStats {
  final int totalDocuments;
  final int totalTitleChars;
  final int totalAuthorChars;
  final int totalContentChars;
  
  SearchIndexStats({
    required this.totalDocuments,
    required this.totalTitleChars,
    required this.totalAuthorChars,
    required this.totalContentChars,
  });
  
  factory SearchIndexStats.fromMap(Map<String, dynamic> map) {
    return SearchIndexStats(
      totalDocuments: map['total_documents'] as int? ?? 0,
      totalTitleChars: map['total_title_chars'] as int? ?? 0,
      totalAuthorChars: map['total_author_chars'] as int? ?? 0,
      totalContentChars: map['total_content_chars'] as int? ?? 0,
    );
  }
  
  double get averageContentLength => 
      totalDocuments > 0 ? totalContentChars / totalDocuments : 0.0;
}

/// Local search exception
class LocalSearchException implements Exception {
  final String message;
  
  LocalSearchException(this.message);
  
  @override
  String toString() => 'LocalSearchException: $message';
}