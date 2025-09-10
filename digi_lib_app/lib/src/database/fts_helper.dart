import 'package:sqflite/sqflite.dart';
import 'package:digi_lib_app/src/database/database_helper.dart';

/// Full-text search helper using SQLite FTS5
class FTSHelper {
  static const String _ftsTableName = 'documents_fts';
  
  /// Initialize FTS5 virtual table
  static Future<void> initializeFTS(Database db) async {
    // Create FTS5 virtual table for full-text search
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS $_ftsTableName USING fts5(
        doc_id UNINDEXED,
        title,
        author,
        filename,
        text_content,
        tags,
        tokenize='porter'
      )
    ''');
    
    // Create triggers to keep FTS table in sync with documents table
    await _createFTSTriggers(db);
  }
  
  /// Create triggers to automatically update FTS table
  static Future<void> _createFTSTriggers(Database db) async {
    // Trigger for INSERT
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS documents_fts_insert AFTER INSERT ON documents
      BEGIN
        INSERT INTO $_ftsTableName(doc_id, title, author, filename, text_content, tags)
        VALUES (
          NEW.id,
          COALESCE(NEW.title, ''),
          COALESCE(NEW.author, ''),
          COALESCE(NEW.filename, ''),
          '',
          ''
        );
      END
    ''');
    
    // Trigger for UPDATE
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS documents_fts_update AFTER UPDATE ON documents
      BEGIN
        UPDATE $_ftsTableName SET
          title = COALESCE(NEW.title, ''),
          author = COALESCE(NEW.author, ''),
          filename = COALESCE(NEW.filename, '')
        WHERE doc_id = NEW.id;
      END
    ''');
    
    // Trigger for DELETE
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS documents_fts_delete AFTER DELETE ON documents
      BEGIN
        DELETE FROM $_ftsTableName WHERE doc_id = OLD.id;
      END
    ''');
  }
  
  /// Index document content for full-text search
  static Future<void> indexDocumentContent(String docId, String textContent) async {
    final db = await DatabaseHelper.instance.database;
    
    await db.execute('''
      UPDATE $_ftsTableName 
      SET text_content = ? 
      WHERE doc_id = ?
    ''', [textContent, docId]);
  }
  
  /// Index document tags for full-text search
  static Future<void> indexDocumentTags(String docId, List<String> tags) async {
    final db = await DatabaseHelper.instance.database;
    final tagsText = tags.join(' ');
    
    await db.execute('''
      UPDATE $_ftsTableName 
      SET tags = ? 
      WHERE doc_id = ?
    ''', [tagsText, docId]);
  }
  
  /// Perform full-text search
  static Future<List<FTSSearchResult>> search(
    String query, {
    int limit = 50,
    int offset = 0,
    List<String>? libraryIds,
    List<String>? tagFilters,
  }) async {
    final db = await DatabaseHelper.instance.database;
    
    // Escape FTS query
    final escapedQuery = _escapeFTSQuery(query);
    
    // Build the search query
    String sql = '''
      SELECT 
        fts.doc_id,
        d.title,
        d.author,
        d.filename,
        d.library_id,
        d.image_url,
        bm25($_ftsTableName) as rank,
        snippet($_ftsTableName, 2, '<mark>', '</mark>', '...', 32) as snippet
      FROM $_ftsTableName fts
      INNER JOIN documents d ON fts.doc_id = d.id
      WHERE $_ftsTableName MATCH ?
    ''';
    
    List<dynamic> args = [escapedQuery];
    
    // Add library filter
    if (libraryIds != null && libraryIds.isNotEmpty) {
      final placeholders = List.filled(libraryIds.length, '?').join(', ');
      sql += ' AND d.library_id IN ($placeholders)';
      args.addAll(libraryIds);
    }
    
    // Add tag filter
    if (tagFilters != null && tagFilters.isNotEmpty) {
      sql += '''
        AND d.id IN (
          SELECT dt.doc_id 
          FROM document_tags dt 
          INNER JOIN tags t ON dt.tag_id = t.id 
          WHERE t.name IN (${List.filled(tagFilters.length, '?').join(', ')})
        )
      ''';
      args.addAll(tagFilters);
    }
    
    sql += ' ORDER BY rank LIMIT ? OFFSET ?';
    args.addAll([limit, offset]);
    
    final results = await db.rawQuery(sql, args);
    
    return results.map((row) => FTSSearchResult.fromMap(row)).toList();
  }
  
  /// Search with highlighting
  static Future<List<FTSSearchResult>> searchWithHighlights(
    String query, {
    int limit = 50,
    int offset = 0,
    List<String>? libraryIds,
    List<String>? tagFilters,
  }) async {
    final db = await DatabaseHelper.instance.database;
    
    // Escape FTS query
    final escapedQuery = _escapeFTSQuery(query);
    
    // Build the search query with multiple snippet columns
    String sql = '''
      SELECT 
        fts.doc_id,
        d.title,
        d.author,
        d.filename,
        d.library_id,
        d.image_url,
        bm25($_ftsTableName) as rank,
        snippet($_ftsTableName, 1, '<mark>', '</mark>', '...', 32) as title_snippet,
        snippet($_ftsTableName, 2, '<mark>', '</mark>', '...', 32) as author_snippet,
        snippet($_ftsTableName, 4, '<mark>', '</mark>', '...', 64) as content_snippet
      FROM $_ftsTableName fts
      INNER JOIN documents d ON fts.doc_id = d.id
      WHERE $_ftsTableName MATCH ?
    ''';
    
    List<dynamic> args = [escapedQuery];
    
    // Add filters (same as above)
    if (libraryIds != null && libraryIds.isNotEmpty) {
      final placeholders = List.filled(libraryIds.length, '?').join(', ');
      sql += ' AND d.library_id IN ($placeholders)';
      args.addAll(libraryIds);
    }
    
    if (tagFilters != null && tagFilters.isNotEmpty) {
      sql += '''
        AND d.id IN (
          SELECT dt.doc_id 
          FROM document_tags dt 
          INNER JOIN tags t ON dt.tag_id = t.id 
          WHERE t.name IN (${List.filled(tagFilters.length, '?').join(', ')})
        )
      ''';
      args.addAll(tagFilters);
    }
    
    sql += ' ORDER BY rank LIMIT ? OFFSET ?';
    args.addAll([limit, offset]);
    
    final results = await db.rawQuery(sql, args);
    
    return results.map((row) => FTSSearchResult.fromMapWithHighlights(row)).toList();
  }
  
  /// Get search suggestions based on partial query
  static Future<List<String>> getSuggestions(String partialQuery, {int limit = 10}) async {
    final db = await DatabaseHelper.instance.database;
    
    if (partialQuery.trim().isEmpty) return [];
    
    // Search for terms that start with the partial query
    final results = await db.rawQuery('''
      SELECT DISTINCT 
        CASE 
          WHEN title LIKE ? THEN title
          WHEN author LIKE ? THEN author
          WHEN filename LIKE ? THEN filename
          ELSE NULL
        END as suggestion
      FROM documents
      WHERE suggestion IS NOT NULL
      ORDER BY suggestion
      LIMIT ?
    ''', ['$partialQuery%', '$partialQuery%', '$partialQuery%', limit]);
    
    return results
        .map((row) => row['suggestion'] as String?)
        .where((suggestion) => suggestion != null)
        .cast<String>()
        .toList();
  }
  
  /// Rebuild FTS index
  static Future<void> rebuildIndex() async {
    final db = await DatabaseHelper.instance.database;
    
    // Clear existing FTS data
    await db.execute('DELETE FROM $_ftsTableName');
    
    // Repopulate from documents table
    await db.execute('''
      INSERT INTO $_ftsTableName(doc_id, title, author, filename, text_content, tags)
      SELECT 
        d.id,
        COALESCE(d.title, ''),
        COALESCE(d.author, ''),
        COALESCE(d.filename, ''),
        COALESCE(GROUP_CONCAT(p.text_content, ' '), ''),
        COALESCE(GROUP_CONCAT(t.name, ' '), '')
      FROM documents d
      LEFT JOIN pages p ON d.id = p.doc_id
      LEFT JOIN document_tags dt ON d.id = dt.doc_id
      LEFT JOIN tags t ON dt.tag_id = t.id
      GROUP BY d.id
    ''');
    
    // Optimize FTS index
    await db.execute('INSERT INTO $_ftsTableName($_ftsTableName) VALUES(\'optimize\')');
  }
  
  /// Get FTS statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    final db = await DatabaseHelper.instance.database;
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_documents,
        SUM(LENGTH(title)) as total_title_chars,
        SUM(LENGTH(author)) as total_author_chars,
        SUM(LENGTH(text_content)) as total_content_chars
      FROM $_ftsTableName
    ''');
    
    return result.first;
  }
  
  /// Escape FTS query to prevent syntax errors
  static String _escapeFTSQuery(String query) {
    // Remove or escape special FTS characters
    String escaped = query
        .replaceAll('"', '""')  // Escape quotes
        .replaceAll('*', '')    // Remove wildcards for now
        .replaceAll(':', '')    // Remove column specifiers
        .trim();
    
    // If query contains spaces, wrap in quotes for phrase search
    if (escaped.contains(' ')) {
      escaped = '"$escaped"';
    }
    
    return escaped;
  }
  
  /// Check if FTS table exists and is properly configured
  static Future<bool> isFTSInitialized() async {
    final db = await DatabaseHelper.instance.database;
    
    final result = await db.rawQuery('''
      SELECT name FROM sqlite_master 
      WHERE type='table' AND name=?
    ''', [_ftsTableName]);
    
    return result.isNotEmpty;
  }
  
  /// Drop and recreate FTS table (for migrations)
  static Future<void> recreateFTS() async {
    final db = await DatabaseHelper.instance.database;
    
    // Drop existing FTS table and triggers
    await db.execute('DROP TABLE IF EXISTS $_ftsTableName');
    await db.execute('DROP TRIGGER IF EXISTS documents_fts_insert');
    await db.execute('DROP TRIGGER IF EXISTS documents_fts_update');
    await db.execute('DROP TRIGGER IF EXISTS documents_fts_delete');
    
    // Recreate FTS table
    await initializeFTS(db);
    
    // Rebuild index
    await rebuildIndex();
  }
}

/// Search result model for FTS queries
class FTSSearchResult {
  final String docId;
  final String? title;
  final String? author;
  final String? filename;
  final String? libraryId;
  final String? imageUrl;
  final double? rank;
  final String? snippet;
  final String? titleSnippet;
  final String? authorSnippet;
  final String? contentSnippet;
  
  FTSSearchResult({
    required this.docId,
    this.title,
    this.author,
    this.filename,
    this.libraryId,
    this.imageUrl,
    this.rank,
    this.snippet,
    this.titleSnippet,
    this.authorSnippet,
    this.contentSnippet,
  });
  
  factory FTSSearchResult.fromMap(Map<String, dynamic> map) {
    return FTSSearchResult(
      docId: map['doc_id'] as String,
      title: map['title'] as String?,
      author: map['author'] as String?,
      filename: map['filename'] as String?,
      libraryId: map['library_id'] as String?,
      imageUrl: map['image_url'] as String?,
      rank: map['rank'] as double?,
      snippet: map['snippet'] as String?,
    );
  }
  
  factory FTSSearchResult.fromMapWithHighlights(Map<String, dynamic> map) {
    return FTSSearchResult(
      docId: map['doc_id'] as String,
      title: map['title'] as String?,
      author: map['author'] as String?,
      filename: map['filename'] as String?,
      libraryId: map['library_id'] as String?,
      imageUrl: map['image_url'] as String?,
      rank: map['rank'] as double?,
      titleSnippet: map['title_snippet'] as String?,
      authorSnippet: map['author_snippet'] as String?,
      contentSnippet: map['content_snippet'] as String?,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'doc_id': docId,
      'title': title,
      'author': author,
      'filename': filename,
      'library_id': libraryId,
      'image_url': imageUrl,
      'rank': rank,
      'snippet': snippet,
      'title_snippet': titleSnippet,
      'author_snippet': authorSnippet,
      'content_snippet': contentSnippet,
    };
  }
}

/// Search filters for FTS queries
class FTSSearchFilters {
  final List<String>? libraryIds;
  final List<String>? tagFilters;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final List<String>? authors;
  final List<String>? fileTypes;
  
  FTSSearchFilters({
    this.libraryIds,
    this.tagFilters,
    this.dateFrom,
    this.dateTo,
    this.authors,
    this.fileTypes,
  });
}

/// Search pagination helper
class FTSSearchPagination {
  final int page;
  final int limit;
  final int totalResults;
  final int totalPages;
  
  FTSSearchPagination({
    required this.page,
    required this.limit,
    required this.totalResults,
  }) : totalPages = (totalResults / limit).ceil();
  
  int get offset => (page - 1) * limit;
  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}