import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/entities/comment.dart';
import '../database_helper.dart';

/// Repository for managing comment data in local SQLite database
class CommentRepository {
  final DatabaseHelper _databaseHelper;

  CommentRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Get all comments for a specific document
  Future<List<Comment>> getCommentsByDocumentId(String documentId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'comments',
      where: 'doc_id = ?',
      whereArgs: [documentId],
      orderBy: 'page_number ASC, created_at ASC',
    );

    return maps.map((map) => _mapToComment(map)).toList();
  }

  /// Get comments for a specific document and page
  Future<List<Comment>> getCommentsByDocumentAndPage(String documentId, int pageNumber) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'comments',
      where: 'doc_id = ? AND page_number = ?',
      whereArgs: [documentId, pageNumber],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => _mapToComment(map)).toList();
  }

  /// Get all comments for a specific user
  Future<List<Comment>> getCommentsByUserId(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'comments',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _mapToComment(map)).toList();
  }

  /// Get a specific comment by ID
  Future<Comment?> getCommentById(String commentId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'comments',
      where: 'id = ?',
      whereArgs: [commentId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToComment(maps.first);
  }

  /// Insert a new comment
  Future<void> insertComment(Comment comment) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'comments',
      _commentToMap(comment),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing comment
  Future<void> updateComment(Comment comment) async {
    final db = await _databaseHelper.database;
    await db.update(
      'comments',
      _commentToMap(comment),
      where: 'id = ?',
      whereArgs: [comment.id],
    );
  }

  /// Delete a comment by ID
  Future<void> deleteComment(String commentId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'comments',
      where: 'id = ?',
      whereArgs: [commentId],
    );
  }

  /// Get all unsynced comments (for offline queue processing)
  Future<List<Comment>> getUnsyncedComments() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'comments',
      where: 'synced = ?',
      whereArgs: [0], // SQLite uses 0 for false
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => _mapToComment(map)).toList();
  }

  /// Mark comment as synced
  Future<void> markCommentAsSynced(String commentId) async {
    final db = await _databaseHelper.database;
    await db.update(
      'comments',
      {'synced': 1}, // SQLite uses 1 for true
      where: 'id = ?',
      whereArgs: [commentId],
    );
  }

  /// Mark comment as unsynced (for conflict resolution)
  Future<void> markCommentAsUnsynced(String commentId) async {
    final db = await _databaseHelper.database;
    await db.update(
      'comments',
      {'synced': 0}, // SQLite uses 0 for false
      where: 'id = ?',
      whereArgs: [commentId],
    );
  }

  /// Get comments count for a document
  Future<int> getCommentsCountByDocumentId(String documentId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM comments WHERE doc_id = ?',
      [documentId],
    );
    return result.first['count'] as int;
  }

  /// Get comments count for a specific page
  Future<int> getCommentsCountByPage(String documentId, int pageNumber) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM comments WHERE doc_id = ? AND page_number = ?',
      [documentId, pageNumber],
    );
    return result.first['count'] as int;
  }

  /// Search comments by content
  Future<List<Comment>> searchComments(String query, {String? documentId}) async {
    final db = await _databaseHelper.database;
    
    String whereClause = 'content LIKE ?';
    List<dynamic> whereArgs = ['%$query%'];
    
    if (documentId != null) {
      whereClause += ' AND doc_id = ?';
      whereArgs.add(documentId);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'comments',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _mapToComment(map)).toList();
  }

  /// Get comments with anchor data (for text selection comments)
  Future<List<Comment>> getCommentsWithAnchors(String documentId, int pageNumber) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'comments',
      where: 'doc_id = ? AND page_number = ? AND anchor IS NOT NULL',
      whereArgs: [documentId, pageNumber],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => _mapToComment(map)).toList();
  }

  /// Delete all comments for a document
  Future<void> deleteCommentsByDocumentId(String documentId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'comments',
      where: 'doc_id = ?',
      whereArgs: [documentId],
    );
  }

  /// Convert database map to Comment entity
  Comment _mapToComment(Map<String, dynamic> map) {
    Map<String, dynamic>? anchor;
    if (map['anchor'] != null) {
      try {
        anchor = jsonDecode(map['anchor'] as String) as Map<String, dynamic>;
      } catch (e) {
        // If JSON parsing fails, set anchor to null
        anchor = null;
      }
    }

    return Comment(
      id: map['id'] as String,
      docId: map['doc_id'] as String,
      userId: map['user_id'] as String?,
      pageNumber: map['page_number'] as int?,
      anchor: anchor,
      content: map['content'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Convert Comment entity to database map
  Map<String, dynamic> _commentToMap(Comment comment) {
    return {
      'id': comment.id,
      'doc_id': comment.docId,
      'user_id': comment.userId,
      'page_number': comment.pageNumber,
      'anchor': comment.anchor != null ? jsonEncode(comment.anchor) : null,
      'content': comment.content,
      'created_at': comment.createdAt.millisecondsSinceEpoch,
      'synced': 0, // Default to unsynced when inserting
    };
  }
}