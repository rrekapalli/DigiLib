import 'dart:async';
import '../models/entities/saved_search.dart';
import '../models/api/search_response.dart';
import '../services/search_service.dart';
import '../database/database_helper.dart';

/// Service for managing saved searches and search analytics
class SavedSearchService {
  final DatabaseHelper _databaseHelper;

  SavedSearchService(this._databaseHelper);

  /// Save a search with a custom name
  Future<SavedSearch> saveSearch({
    required String name,
    required String query,
    SearchFilters? filters,
  }) async {
    final savedSearch = SavedSearch(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      query: query,
      filters: filters?.toMap(),
      createdAt: DateTime.now(),
      useCount: 0,
    );

    await _insertSavedSearch(savedSearch);
    return savedSearch;
  }

  /// Get all saved searches
  Future<List<SavedSearch>> getSavedSearches() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'saved_searches',
      orderBy: 'last_used_at DESC, created_at DESC',
    );

    return maps.map((map) => _savedSearchFromMap(map)).toList();
  }

  /// Get a saved search by ID
  Future<SavedSearch?> getSavedSearch(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'saved_searches',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _savedSearchFromMap(maps.first);
  }

  /// Update a saved search
  Future<SavedSearch> updateSavedSearch(SavedSearch savedSearch) async {
    await _updateSavedSearch(savedSearch);
    return savedSearch;
  }

  /// Delete a saved search
  Future<void> deleteSavedSearch(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'saved_searches',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Use a saved search (increment use count and update last used)
  Future<SavedSearch> useSavedSearch(String id) async {
    final savedSearch = await getSavedSearch(id);
    if (savedSearch == null) {
      throw Exception('Saved search not found');
    }

    final updatedSearch = savedSearch.copyWith(
      lastUsedAt: DateTime.now(),
      useCount: savedSearch.useCount + 1,
    );

    await _updateSavedSearch(updatedSearch);
    return updatedSearch;
  }

  /// Record search analytics
  Future<void> recordSearchAnalytics({
    required String query,
    required int resultCount,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();

    // Check if analytics record exists for this query
    final existing = await db.query(
      'search_analytics',
      where: 'query = ?',
      whereArgs: [query],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Update existing record
      final currentData = existing.first;
      final searchCount = (currentData['search_count'] as int) + 1;
      final totalResults = (currentData['total_results'] as int) + resultCount;
      final avgResultCount = totalResults / searchCount;

      await db.update(
        'search_analytics',
        {
          'search_count': searchCount,
          'last_searched': now.millisecondsSinceEpoch,
          'total_results': totalResults,
          'avg_result_count': avgResultCount,
        },
        where: 'query = ?',
        whereArgs: [query],
      );
    } else {
      // Insert new record
      await db.insert('search_analytics', {
        'query': query,
        'search_count': 1,
        'first_searched': now.millisecondsSinceEpoch,
        'last_searched': now.millisecondsSinceEpoch,
        'total_results': resultCount,
        'avg_result_count': resultCount.toDouble(),
      });
    }
  }

  /// Get search analytics
  Future<List<SearchAnalytics>> getSearchAnalytics({
    int limit = 50,
    String? orderBy,
  }) async {
    final db = await _databaseHelper.database;
    final orderByClause = orderBy ?? 'search_count DESC, last_searched DESC';
    
    final maps = await db.query(
      'search_analytics',
      orderBy: orderByClause,
      limit: limit,
    );

    return maps.map((map) => _searchAnalyticsFromMap(map)).toList();
  }

  /// Get popular search queries
  Future<List<String>> getPopularQueries({int limit = 10}) async {
    final analytics = await getSearchAnalytics(
      limit: limit,
      orderBy: 'search_count DESC',
    );
    return analytics.map((a) => a.query).toList();
  }

  /// Get recent search queries
  Future<List<String>> getRecentQueries({int limit = 10}) async {
    final analytics = await getSearchAnalytics(
      limit: limit,
      orderBy: 'last_searched DESC',
    );
    return analytics.map((a) => a.query).toList();
  }

  /// Clear all search analytics
  Future<void> clearSearchAnalytics() async {
    final db = await _databaseHelper.database;
    await db.delete('search_analytics');
  }

  /// Export search results to various formats
  Future<String> exportSearchResults({
    required List<SearchResult> results,
    required String format, // 'csv', 'json', 'txt'
    String? query,
  }) async {
    switch (format.toLowerCase()) {
      case 'csv':
        return _exportToCsv(results, query);
      case 'json':
        return _exportToJson(results, query);
      case 'txt':
        return _exportToText(results, query);
      default:
        throw ArgumentError('Unsupported export format: $format');
    }
  }

  /// Share search results
  Future<Map<String, dynamic>> shareSearchResults({
    required List<SearchResult> results,
    required String query,
    SearchFilters? filters,
  }) async {
    final shareData = {
      'query': query,
      'filters': filters?.toMap(),
      'results_count': results.length,
      'results': results.map((r) => {
        'document_id': r.document.id,
        'title': r.document.title,
        'author': r.document.author,
        'highlights_count': r.highlights.length,
      }).toList(),
      'exported_at': DateTime.now().toIso8601String(),
    };

    return shareData;
  }

  // Private helper methods

  Future<void> _insertSavedSearch(SavedSearch savedSearch) async {
    final db = await _databaseHelper.database;
    await db.insert('saved_searches', _savedSearchToMap(savedSearch));
  }

  Future<void> _updateSavedSearch(SavedSearch savedSearch) async {
    final db = await _databaseHelper.database;
    await db.update(
      'saved_searches',
      _savedSearchToMap(savedSearch),
      where: 'id = ?',
      whereArgs: [savedSearch.id],
    );
  }

  Map<String, dynamic> _savedSearchToMap(SavedSearch savedSearch) {
    return {
      'id': savedSearch.id,
      'name': savedSearch.name,
      'query': savedSearch.query,
      'filters': savedSearch.filters != null 
          ? _databaseHelper.encodeJson(savedSearch.filters!) 
          : null,
      'created_at': savedSearch.createdAt.millisecondsSinceEpoch,
      'last_used_at': savedSearch.lastUsedAt?.millisecondsSinceEpoch,
      'use_count': savedSearch.useCount,
    };
  }

  SavedSearch _savedSearchFromMap(Map<String, dynamic> map) {
    return SavedSearch(
      id: map['id'] as String,
      name: map['name'] as String,
      query: map['query'] as String,
      filters: map['filters'] != null 
          ? _databaseHelper.decodeJson(map['filters'] as String) 
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      lastUsedAt: map['last_used_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['last_used_at'] as int) 
          : null,
      useCount: map['use_count'] as int,
    );
  }

  SearchAnalytics _searchAnalyticsFromMap(Map<String, dynamic> map) {
    return SearchAnalytics(
      query: map['query'] as String,
      searchCount: map['search_count'] as int,
      firstSearched: DateTime.fromMillisecondsSinceEpoch(map['first_searched'] as int),
      lastSearched: DateTime.fromMillisecondsSinceEpoch(map['last_searched'] as int),
      resultCount: map['total_results'] as int,
      avgResultCount: map['avg_result_count'] as double,
    );
  }

  String _exportToCsv(List<SearchResult> results, String? query) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Title,Author,File Type,Size,Page Count,Highlights');
    
    // Add query info if provided
    if (query != null) {
      buffer.writeln('# Search Query: $query');
      buffer.writeln('# Results: ${results.length}');
      buffer.writeln('# Exported: ${DateTime.now().toIso8601String()}');
      buffer.writeln();
    }
    
    // Data rows
    for (final result in results) {
      final doc = result.document;
      buffer.writeln([
        _escapeCsv(doc.title ?? doc.filename ?? 'Untitled'),
        _escapeCsv(doc.author ?? ''),
        doc.extension ?? '',
        doc.sizeBytes?.toString() ?? '',
        doc.pageCount?.toString() ?? '',
        result.highlights.length.toString(),
      ].join(','));
    }
    
    return buffer.toString();
  }

  String _exportToJson(List<SearchResult> results, String? query) {
    final data = {
      'query': query,
      'results_count': results.length,
      'exported_at': DateTime.now().toIso8601String(),
      'results': results.map((r) => r.toJson()).toList(),
    };
    
    return _databaseHelper.encodeJson(data);
  }

  String _exportToText(List<SearchResult> results, String? query) {
    final buffer = StringBuffer();
    
    if (query != null) {
      buffer.writeln('Search Results for: "$query"');
      buffer.writeln('Results: ${results.length}');
      buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
      buffer.writeln('=' * 50);
      buffer.writeln();
    }
    
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final doc = result.document;
      
      buffer.writeln('${i + 1}. ${doc.title ?? doc.filename ?? 'Untitled'}');
      if (doc.author != null) {
        buffer.writeln('   Author: ${doc.author}');
      }
      if (doc.extension != null) {
        buffer.writeln('   Type: ${doc.extension!.toUpperCase()}');
      }
      if (result.highlights.isNotEmpty) {
        buffer.writeln('   Highlights: ${result.highlights.length}');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

