import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/entities/tag.dart';
import '../../models/entities/document.dart';
import '../database_helper.dart';

/// Repository for managing tag data in local SQLite database
class TagRepository {
  final DatabaseHelper _databaseHelper;

  TagRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Get all tags for a specific owner
  Future<List<Tag>> getTagsByOwnerId(String ownerId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => _mapToTag(map)).toList();
  }

  /// Get all tags (for global search)
  Future<List<Tag>> getAllTags() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      orderBy: 'name ASC',
    );

    return maps.map((map) => _mapToTag(map)).toList();
  }

  /// Get a specific tag by ID
  Future<Tag?> getTagById(String tagId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      where: 'id = ?',
      whereArgs: [tagId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToTag(maps.first);
  }

  /// Get tag by name and owner
  Future<Tag?> getTagByName(String name, String ownerId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      where: 'name = ? AND owner_id = ?',
      whereArgs: [name, ownerId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToTag(maps.first);
  }

  /// Insert a new tag
  Future<void> insertTag(Tag tag) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'tags',
      _tagToMap(tag),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing tag
  Future<void> updateTag(Tag tag) async {
    final db = await _databaseHelper.database;
    await db.update(
      'tags',
      _tagToMap(tag),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  /// Delete a tag by ID
  Future<void> deleteTag(String tagId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'tags',
      where: 'id = ?',
      whereArgs: [tagId],
    );
  }

  /// Get tags for a specific document
  Future<List<Tag>> getDocumentTags(String documentId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN document_tags dt ON t.id = dt.tag_id
      WHERE dt.doc_id = ?
      ORDER BY t.name ASC
    ''', [documentId]);

    return maps.map((map) => _mapToTag(map)).toList();
  }

  /// Get documents for a specific tag
  Future<List<Document>> getDocumentsByTag(String tagId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT d.* FROM documents d
      INNER JOIN document_tags dt ON d.id = dt.doc_id
      WHERE dt.tag_id = ?
      ORDER BY d.title ASC
    ''', [tagId]);

    return maps.map((map) => _mapToDocument(map)).toList();
  }

  /// Add tag to document
  Future<void> addTagToDocument(String documentId, String tagId) async {
    final db = await _databaseHelper.database;
    final documentTag = DocumentTag(
      id: _generateDocumentTagId(),
      docId: documentId,
      tagId: tagId,
      createdAt: DateTime.now(),
    );

    await db.insert(
      'document_tags',
      _documentTagToMap(documentTag),
      conflictAlgorithm: ConflictAlgorithm.ignore, // Ignore if already exists
    );
  }

  /// Remove tag from document
  Future<void> removeTagFromDocument(String documentId, String tagId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'document_tags',
      where: 'doc_id = ? AND tag_id = ?',
      whereArgs: [documentId, tagId],
    );
  }

  /// Check if document has tag
  Future<bool> documentHasTag(String documentId, String tagId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'document_tags',
      where: 'doc_id = ? AND tag_id = ?',
      whereArgs: [documentId, tagId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Get tag usage count (number of documents using the tag)
  Future<int> getTagUsageCount(String tagId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM document_tags WHERE tag_id = ?',
      [tagId],
    );
    return result.first['count'] as int;
  }

  /// Get popular tags (most used tags)
  Future<List<TagWithCount>> getPopularTags({int limit = 10}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.*, COUNT(dt.doc_id) as usage_count
      FROM tags t
      LEFT JOIN document_tags dt ON t.id = dt.tag_id
      GROUP BY t.id
      ORDER BY usage_count DESC, t.name ASC
      LIMIT ?
    ''', [limit]);

    return maps.map((map) => TagWithCount(
      tag: _mapToTag(map),
      count: map['usage_count'] as int,
    )).toList();
  }

  /// Search tags by name
  Future<List<Tag>> searchTags(String query, {String? ownerId}) async {
    final db = await _databaseHelper.database;
    final String whereClause = ownerId != null 
        ? 'name LIKE ? AND owner_id = ?'
        : 'name LIKE ?';
    final List<dynamic> whereArgs = ownerId != null 
        ? ['%$query%', ownerId]
        : ['%$query%'];

    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((map) => _mapToTag(map)).toList();
  }

  /// Get unused tags (tags not assigned to any document)
  Future<List<Tag>> getUnusedTags({String? ownerId}) async {
    final db = await _databaseHelper.database;
    final String whereClause = ownerId != null 
        ? 'WHERE t.owner_id = ?'
        : '';
    final List<dynamic> whereArgs = ownerId != null ? [ownerId] : [];

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.* FROM tags t
      LEFT JOIN document_tags dt ON t.id = dt.tag_id
      $whereClause
      GROUP BY t.id
      HAVING COUNT(dt.doc_id) = 0
      ORDER BY t.name ASC
    ''', whereArgs);

    return maps.map((map) => _mapToTag(map)).toList();
  }

  /// Generate a unique document tag ID
  String _generateDocumentTagId() {
    return 'dt_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Convert database map to Tag entity
  Tag _mapToTag(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String?,
      name: map['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Convert Tag entity to database map
  Map<String, dynamic> _tagToMap(Tag tag) {
    return {
      'id': tag.id,
      'owner_id': tag.ownerId,
      'name': tag.name,
      'created_at': tag.createdAt.millisecondsSinceEpoch,
    };
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

  /// Convert DocumentTag entity to database map
  Map<String, dynamic> _documentTagToMap(DocumentTag documentTag) {
    return {
      'id': documentTag.id,
      'doc_id': documentTag.docId,
      'tag_id': documentTag.tagId,
      'created_at': documentTag.createdAt.millisecondsSinceEpoch,
    };
  }
}

/// Model for tag with usage count
class TagWithCount {
  final Tag tag;
  final int count;

  const TagWithCount({
    required this.tag,
    required this.count,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagWithCount &&
        other.tag == tag &&
        other.count == count;
  }

  @override
  int get hashCode => Object.hash(tag, count);

  @override
  String toString() => 'TagWithCount(tag: $tag, count: $count)';
}