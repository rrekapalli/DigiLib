import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/entities/bookmark.dart';
import '../database_helper.dart';

/// Repository for managing bookmark data in local SQLite database
class BookmarkRepository {
  final DatabaseHelper _databaseHelper;

  BookmarkRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Get all bookmarks for a specific document
  Future<List<Bookmark>> getBookmarksByDocumentId(String documentId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'doc_id = ?',
      whereArgs: [documentId],
      orderBy: 'page_number ASC, created_at ASC',
    );

    return maps.map((map) => _mapToBookmark(map)).toList();
  }

  /// Get all bookmarks for a specific user
  Future<List<Bookmark>> getBookmarksByUserId(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _mapToBookmark(map)).toList();
  }

  /// Get a specific bookmark by ID
  Future<Bookmark?> getBookmarkById(String bookmarkId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'id = ?',
      whereArgs: [bookmarkId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToBookmark(maps.first);
  }

  /// Insert a new bookmark
  Future<void> insertBookmark(Bookmark bookmark) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'bookmarks',
      _bookmarkToMap(bookmark),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing bookmark
  Future<void> updateBookmark(Bookmark bookmark) async {
    final db = await _databaseHelper.database;
    await db.update(
      'bookmarks',
      _bookmarkToMap(bookmark),
      where: 'id = ?',
      whereArgs: [bookmark.id],
    );
  }

  /// Delete a bookmark by ID
  Future<void> deleteBookmark(String bookmarkId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'bookmarks',
      where: 'id = ?',
      whereArgs: [bookmarkId],
    );
  }

  /// Get all unsynced bookmarks (for offline queue processing)
  Future<List<Bookmark>> getUnsyncedBookmarks() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'synced = ?',
      whereArgs: [0], // SQLite uses 0 for false
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => _mapToBookmark(map)).toList();
  }

  /// Mark bookmark as synced
  Future<void> markBookmarkAsSynced(String bookmarkId) async {
    final db = await _databaseHelper.database;
    await db.update(
      'bookmarks',
      {'synced': 1}, // SQLite uses 1 for true
      where: 'id = ?',
      whereArgs: [bookmarkId],
    );
  }

  /// Mark bookmark as unsynced (for conflict resolution)
  Future<void> markBookmarkAsUnsynced(String bookmarkId) async {
    final db = await _databaseHelper.database;
    await db.update(
      'bookmarks',
      {'synced': 0}, // SQLite uses 0 for false
      where: 'id = ?',
      whereArgs: [bookmarkId],
    );
  }

  /// Get bookmarks count for a document
  Future<int> getBookmarksCountByDocumentId(String documentId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM bookmarks WHERE doc_id = ?',
      [documentId],
    );
    return result.first['count'] as int;
  }

  /// Check if a bookmark exists at a specific page
  Future<bool> hasBookmarkAtPage(String documentId, int pageNumber) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'bookmarks',
      where: 'doc_id = ? AND page_number = ?',
      whereArgs: [documentId, pageNumber],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Get bookmark at a specific page
  Future<Bookmark?> getBookmarkAtPage(String documentId, int pageNumber) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'doc_id = ? AND page_number = ?',
      whereArgs: [documentId, pageNumber],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToBookmark(maps.first);
  }

  /// Convert database map to Bookmark entity
  Bookmark _mapToBookmark(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      docId: map['doc_id'] as String,
      pageNumber: map['page_number'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Convert Bookmark entity to database map
  Map<String, dynamic> _bookmarkToMap(Bookmark bookmark) {
    return {
      'id': bookmark.id,
      'user_id': bookmark.userId,
      'doc_id': bookmark.docId,
      'page_number': bookmark.pageNumber,
      'note': bookmark.note,
      'created_at': bookmark.createdAt.millisecondsSinceEpoch,
      'synced': 0, // Default to unsynced when inserting
    };
  }
}