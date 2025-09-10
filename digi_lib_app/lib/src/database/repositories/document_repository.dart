import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/entities/document.dart';
import '../database_helper.dart';

/// Query parameters for document filtering
class DocumentQuery {
  final String? libraryId;
  final String? search;
  final List<String>? tagIds;
  final String? author;
  final String? format;
  final int? yearPublished;
  final String? status;
  final String? sortBy; // title, author, created_at, updated_at, size_bytes
  final bool ascending;
  final int? limit;
  final int? offset;

  const DocumentQuery({
    this.libraryId,
    this.search,
    this.tagIds,
    this.author,
    this.format,
    this.yearPublished,
    this.status,
    this.sortBy = 'title',
    this.ascending = true,
    this.limit,
    this.offset,
  });

  DocumentQuery copyWith({
    String? libraryId,
    String? search,
    List<String>? tagIds,
    String? author,
    String? format,
    int? yearPublished,
    String? status,
    String? sortBy,
    bool? ascending,
    int? limit,
    int? offset,
  }) {
    return DocumentQuery(
      libraryId: libraryId ?? this.libraryId,
      search: search ?? this.search,
      tagIds: tagIds ?? this.tagIds,
      author: author ?? this.author,
      format: format ?? this.format,
      yearPublished: yearPublished ?? this.yearPublished,
      status: status ?? this.status,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

/// Repository for managing document data in local SQLite database
class DocumentRepository {
  final DatabaseHelper _databaseHelper;

  DocumentRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Get all documents with optional filtering and pagination
  Future<List<Document>> findAll({DocumentQuery? query}) async {
    final db = await _databaseHelper.database;
    
    // Build the base query
    String sql = 'SELECT DISTINCT d.* FROM documents d';
    final List<dynamic> args = [];
    final List<String> whereClauses = [];
    
    // Join with document_tags if filtering by tags
    if (query?.tagIds != null && query!.tagIds!.isNotEmpty) {
      sql += ' INNER JOIN document_tags dt ON d.id = dt.doc_id';
      final tagPlaceholders = query.tagIds!.map((_) => '?').join(',');
      whereClauses.add('dt.tag_id IN ($tagPlaceholders)');
      args.addAll(query.tagIds!);
    }
    
    // Add WHERE clauses
    if (query?.libraryId != null) {
      whereClauses.add('d.library_id = ?');
      args.add(query!.libraryId);
    }
    
    if (query?.author != null) {
      whereClauses.add('d.author LIKE ?');
      args.add('%${query!.author}%');
    }
    
    if (query?.format != null) {
      whereClauses.add('d.format = ?');
      args.add(query!.format);
    }
    
    if (query?.yearPublished != null) {
      whereClauses.add('d.year_published = ?');
      args.add(query!.yearPublished);
    }
    
    if (query?.status != null) {
      whereClauses.add('d.status = ?');
      args.add(query!.status);
    }
    
    if (query?.search != null && query!.search!.isNotEmpty) {
      whereClauses.add('''
        (d.title LIKE ? OR 
         d.author LIKE ? OR 
         d.filename LIKE ? OR 
         d.renamed_name LIKE ?)
      ''');
      final searchTerm = '%${query.search}%';
      args.addAll([searchTerm, searchTerm, searchTerm, searchTerm]);
    }
    
    // Add WHERE clause if we have conditions
    if (whereClauses.isNotEmpty) {
      sql += ' WHERE ${whereClauses.join(' AND ')}';
    }
    
    // Add ORDER BY
    final sortColumn = _getSortColumn(query?.sortBy ?? 'title');
    final sortDirection = (query?.ascending ?? true) ? 'ASC' : 'DESC';
    sql += ' ORDER BY d.$sortColumn $sortDirection';
    
    // Add LIMIT and OFFSET
    if (query?.limit != null) {
      sql += ' LIMIT ?';
      args.add(query!.limit);
      
      if (query.offset != null) {
        sql += ' OFFSET ?';
        args.add(query.offset);
      }
    }
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);
    return maps.map((map) => _mapToDocument(map)).toList();
  }

  /// Get a specific document by ID
  Future<Document?> findById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToDocument(maps.first);
  }

  /// Save a document (insert or update)
  Future<void> save(Document document) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'documents',
      _documentToMap(document),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Save multiple documents
  Future<void> saveAll(List<Document> documents) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    
    for (final document in documents) {
      batch.insert(
        'documents',
        _documentToMap(document),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  /// Delete a document by ID
  Future<void> delete(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search documents using full-text search
  Future<List<Document>> search(String query) async {
    final db = await _databaseHelper.database;
    
    // Use FTS5 for full-text search if available
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT d.* FROM documents d
        INNER JOIN documents_fts fts ON d.id = fts.rowid
        WHERE documents_fts MATCH ?
        ORDER BY rank
      ''', [query]);
      
      return maps.map((map) => _mapToDocument(map)).toList();
    } catch (e) {
      // Fallback to LIKE search if FTS is not available
      return findAll(query: DocumentQuery(search: query));
    }
  }

  /// Get documents by tag ID with pagination
  Future<List<Document>> findByTagId(String tagId, {int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    
    String sql = '''
      SELECT d.* FROM documents d
      INNER JOIN document_tags dt ON d.id = dt.doc_id
      WHERE dt.tag_id = ?
      ORDER BY d.title ASC
    ''';
    
    final List<dynamic> args = [tagId];
    
    if (limit != null) {
      sql += ' LIMIT ?';
      args.add(limit);
      
      if (offset != null) {
        sql += ' OFFSET ?';
        args.add(offset);
      }
    }
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);
    return maps.map((map) => _mapToDocument(map)).toList();
  }

  /// Get documents by multiple tag IDs (documents that have ALL specified tags)
  Future<List<Document>> findByAllTags(List<String> tagIds) async {
    if (tagIds.isEmpty) return [];
    
    final db = await _databaseHelper.database;
    
    // Build query to find documents that have ALL specified tags
    final tagPlaceholders = tagIds.map((_) => '?').join(',');
    final sql = '''
      SELECT d.* FROM documents d
      WHERE d.id IN (
        SELECT dt.doc_id FROM document_tags dt
        WHERE dt.tag_id IN ($tagPlaceholders)
        GROUP BY dt.doc_id
        HAVING COUNT(DISTINCT dt.tag_id) = ?
      )
      ORDER BY d.title ASC
    ''';
    
    final args = [...tagIds, tagIds.length];
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);
    return maps.map((map) => _mapToDocument(map)).toList();
  }

  /// Get documents by any of the specified tag IDs (documents that have ANY of the specified tags)
  Future<List<Document>> findByAnyTags(List<String> tagIds) async {
    if (tagIds.isEmpty) return [];
    
    final db = await _databaseHelper.database;
    
    final tagPlaceholders = tagIds.map((_) => '?').join(',');
    final sql = '''
      SELECT DISTINCT d.* FROM documents d
      INNER JOIN document_tags dt ON d.id = dt.doc_id
      WHERE dt.tag_id IN ($tagPlaceholders)
      ORDER BY d.title ASC
    ''';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, tagIds);
    return maps.map((map) => _mapToDocument(map)).toList();
  }

  /// Get document count by tag ID
  Future<int> getDocumentCountByTag(String tagId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM document_tags
      WHERE tag_id = ?
    ''', [tagId]);
    return result.first['count'] as int;
  }

  /// Get documents without any tags
  Future<List<Document>> findUntaggedDocuments({int? limit, int? offset}) async {
    final db = await _databaseHelper.database;
    
    String sql = '''
      SELECT d.* FROM documents d
      LEFT JOIN document_tags dt ON d.id = dt.doc_id
      WHERE dt.doc_id IS NULL
      ORDER BY d.title ASC
    ''';
    
    final List<dynamic> args = [];
    
    if (limit != null) {
      sql += ' LIMIT ?';
      args.add(limit);
      
      if (offset != null) {
        sql += ' OFFSET ?';
        args.add(offset);
      }
    }
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);
    return maps.map((map) => _mapToDocument(map)).toList();
  }

  /// Get total document count with optional filtering
  Future<int> getCount({DocumentQuery? query}) async {
    final db = await _databaseHelper.database;
    
    // Build the base query
    String sql = 'SELECT COUNT(DISTINCT d.id) as count FROM documents d';
    final List<dynamic> args = [];
    final List<String> whereClauses = [];
    
    // Join with document_tags if filtering by tags
    if (query?.tagIds != null && query!.tagIds!.isNotEmpty) {
      sql += ' INNER JOIN document_tags dt ON d.id = dt.doc_id';
      final tagPlaceholders = query.tagIds!.map((_) => '?').join(',');
      whereClauses.add('dt.tag_id IN ($tagPlaceholders)');
      args.addAll(query.tagIds!);
    }
    
    // Add WHERE clauses (same logic as findAll)
    if (query?.libraryId != null) {
      whereClauses.add('d.library_id = ?');
      args.add(query!.libraryId);
    }
    
    if (query?.author != null) {
      whereClauses.add('d.author LIKE ?');
      args.add('%${query!.author}%');
    }
    
    if (query?.format != null) {
      whereClauses.add('d.format = ?');
      args.add(query!.format);
    }
    
    if (query?.yearPublished != null) {
      whereClauses.add('d.year_published = ?');
      args.add(query!.yearPublished);
    }
    
    if (query?.status != null) {
      whereClauses.add('d.status = ?');
      args.add(query!.status);
    }
    
    if (query?.search != null && query!.search!.isNotEmpty) {
      whereClauses.add('''
        (d.title LIKE ? OR 
         d.author LIKE ? OR 
         d.filename LIKE ? OR 
         d.renamed_name LIKE ?)
      ''');
      final searchTerm = '%${query.search}%';
      args.addAll([searchTerm, searchTerm, searchTerm, searchTerm]);
    }
    
    // Add WHERE clause if we have conditions
    if (whereClauses.isNotEmpty) {
      sql += ' WHERE ${whereClauses.join(' AND ')}';
    }
    
    final result = await db.rawQuery(sql, args);
    return result.first['count'] as int;
  }

  /// Get unique authors
  Future<List<String>> getAuthors() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT author FROM documents 
      WHERE author IS NOT NULL AND author != ''
      ORDER BY author ASC
    ''');
    return maps.map((map) => map['author'] as String).toList();
  }

  /// Get unique formats
  Future<List<String>> getFormats() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT format FROM documents 
      WHERE format IS NOT NULL AND format != ''
      ORDER BY format ASC
    ''');
    return maps.map((map) => map['format'] as String).toList();
  }

  /// Get year range (min and max years)
  Future<Map<String, int?>> getYearRange() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT MIN(year_published) as min_year, MAX(year_published) as max_year
      FROM documents 
      WHERE year_published IS NOT NULL
    ''');
    
    final row = result.first;
    return {
      'min': row['min_year'] as int?,
      'max': row['max_year'] as int?,
    };
  }

  /// Get sort column name for SQL query
  String _getSortColumn(String sortBy) {
    switch (sortBy) {
      case 'title':
        return 'title';
      case 'author':
        return 'author';
      case 'created_at':
        return 'created_at';
      case 'updated_at':
        return 'updated_at';
      case 'size_bytes':
        return 'size_bytes';
      case 'year_published':
        return 'year_published';
      default:
        return 'title';
    }
  }

  /// Convert database map to Document entity
  Document _mapToDocument(Map<String, dynamic> map) {
    return Document(
      id: map['id'] as String,
      libraryId: map['library_id'] as String,
      title: map['title'] as String?,
      author: map['author'] as String?,
      filename: map['filename'] as String?,
      relativePath: map['relative_path'] as String?,
      fullPath: map['full_path'] as String?,
      extension: map['extension'] as String?,
      renamedName: map['renamed_name'] as String?,
      isbn: map['isbn'] as String?,
      yearPublished: map['year_published'] as int?,
      status: map['status'] as String?,
      cloudId: map['cloud_id'] as String?,
      sha256: map['sha256'] as String?,
      sizeBytes: map['size_bytes'] as int?,
      pageCount: map['page_count'] as int?,
      format: map['format'] as String?,
      imageUrl: map['image_url'] as String?,
      amazonUrl: map['amazon_url'] as String?,
      reviewUrl: map['review_url'] as String?,
      metadataJson: map['metadata_json'] != null 
          ? Map<String, dynamic>.from(map['metadata_json'] as Map)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Convert Document entity to database map
  Map<String, dynamic> _documentToMap(Document document) {
    return {
      'id': document.id,
      'library_id': document.libraryId,
      'title': document.title,
      'author': document.author,
      'filename': document.filename,
      'relative_path': document.relativePath,
      'full_path': document.fullPath,
      'extension': document.extension,
      'renamed_name': document.renamedName,
      'isbn': document.isbn,
      'year_published': document.yearPublished,
      'status': document.status,
      'cloud_id': document.cloudId,
      'sha256': document.sha256,
      'size_bytes': document.sizeBytes,
      'page_count': document.pageCount,
      'format': document.format,
      'image_url': document.imageUrl,
      'amazon_url': document.amazonUrl,
      'review_url': document.reviewUrl,
      'metadata_json': document.metadataJson,
      'created_at': document.createdAt.millisecondsSinceEpoch,
      'updated_at': document.updatedAt.millisecondsSinceEpoch,
      'synced_at': null, // Default to unsynced when inserting
    };
  }
}