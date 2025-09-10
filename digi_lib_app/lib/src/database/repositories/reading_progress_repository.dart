import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/entities/reading_progress.dart';
import '../database_helper.dart';

/// Repository for managing reading progress data in local SQLite database
class ReadingProgressRepository {
  final DatabaseHelper _databaseHelper;

  ReadingProgressRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Get reading progress for a specific document and user
  Future<ReadingProgress?> getReadingProgress(String userId, String documentId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_progress',
      where: 'user_id = ? AND doc_id = ?',
      whereArgs: [userId, documentId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToReadingProgress(maps.first);
  }

  /// Get all reading progress for a specific user
  Future<List<ReadingProgress>> getReadingProgressByUserId(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => _mapToReadingProgress(map)).toList();
  }

  /// Get recently read documents for a user
  Future<List<ReadingProgress>> getRecentlyReadDocuments(String userId, {int limit = 10}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_progress',
      where: 'user_id = ? AND last_page IS NOT NULL',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
      limit: limit,
    );

    return maps.map((map) => _mapToReadingProgress(map)).toList();
  }

  /// Insert or update reading progress
  Future<void> upsertReadingProgress(ReadingProgress progress) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'reading_progress',
      _readingProgressToMap(progress),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update reading progress for a document
  Future<void> updateReadingProgress(String userId, String documentId, int lastPage) async {
    final db = await _databaseHelper.database;
    final progress = ReadingProgress(
      userId: userId,
      docId: documentId,
      lastPage: lastPage,
      updatedAt: DateTime.now(),
    );

    await db.insert(
      'reading_progress',
      _readingProgressToMap(progress),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete reading progress for a document
  Future<void> deleteReadingProgress(String userId, String documentId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'reading_progress',
      where: 'user_id = ? AND doc_id = ?',
      whereArgs: [userId, documentId],
    );
  }

  /// Delete all reading progress for a user
  Future<void> deleteReadingProgressByUserId(String userId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'reading_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Delete all reading progress for a document (all users)
  Future<void> deleteReadingProgressByDocumentId(String documentId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'reading_progress',
      where: 'doc_id = ?',
      whereArgs: [documentId],
    );
  }

  /// Get all unsynced reading progress (for offline queue processing)
  Future<List<ReadingProgress>> getUnsyncedReadingProgress() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_progress',
      where: 'synced = ?',
      whereArgs: [0], // SQLite uses 0 for false
      orderBy: 'updated_at ASC',
    );

    return maps.map((map) => _mapToReadingProgress(map)).toList();
  }

  /// Mark reading progress as synced
  Future<void> markReadingProgressAsSynced(String userId, String documentId) async {
    final db = await _databaseHelper.database;
    await db.update(
      'reading_progress',
      {'synced': 1}, // SQLite uses 1 for true
      where: 'user_id = ? AND doc_id = ?',
      whereArgs: [userId, documentId],
    );
  }

  /// Mark reading progress as unsynced (for conflict resolution)
  Future<void> markReadingProgressAsUnsynced(String userId, String documentId) async {
    final db = await _databaseHelper.database;
    await db.update(
      'reading_progress',
      {'synced': 0}, // SQLite uses 0 for false
      where: 'user_id = ? AND doc_id = ?',
      whereArgs: [userId, documentId],
    );
  }

  /// Get reading progress count for a user
  Future<int> getReadingProgressCount(String userId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM reading_progress WHERE user_id = ?',
      [userId],
    );
    return result.first['count'] as int;
  }

  /// Get documents with reading progress (partially read)
  Future<List<ReadingProgress>> getDocumentsInProgress(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_progress',
      where: 'user_id = ? AND last_page IS NOT NULL AND last_page > 0',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => _mapToReadingProgress(map)).toList();
  }

  /// Check if document has been read (has progress)
  Future<bool> hasReadingProgress(String userId, String documentId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'reading_progress',
      where: 'user_id = ? AND doc_id = ?',
      whereArgs: [userId, documentId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Get reading progress percentage (requires document page count)
  Future<double?> getReadingProgressPercentage(String userId, String documentId, int totalPages) async {
    final progress = await getReadingProgress(userId, documentId);
    if (progress?.lastPage == null || totalPages <= 0) return null;
    
    return (progress!.lastPage! / totalPages) * 100;
  }

  /// Batch update reading progress (for sync operations)
  Future<void> batchUpsertReadingProgress(List<ReadingProgress> progressList) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    
    for (final progress in progressList) {
      batch.insert(
        'reading_progress',
        _readingProgressToMap(progress),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  /// Convert database map to ReadingProgress entity
  ReadingProgress _mapToReadingProgress(Map<String, dynamic> map) {
    return ReadingProgress(
      userId: map['user_id'] as String,
      docId: map['doc_id'] as String,
      lastPage: map['last_page'] as int?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Convert ReadingProgress entity to database map
  Map<String, dynamic> _readingProgressToMap(ReadingProgress progress) {
    return {
      'user_id': progress.userId,
      'doc_id': progress.docId,
      'last_page': progress.lastPage,
      'updated_at': progress.updatedAt.millisecondsSinceEpoch,
      'synced': 0, // Default to unsynced when inserting
    };
  }
}