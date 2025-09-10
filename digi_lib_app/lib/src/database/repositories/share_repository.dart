import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/entities/share.dart';
import '../database_helper.dart';

/// Repository for managing share data in local SQLite database
class ShareRepository {
  final DatabaseHelper _databaseHelper;

  ShareRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Get all shares owned by a specific user
  Future<List<Share>> getSharesByOwnerId(String ownerId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shares',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _mapToShare(map)).toList();
  }

  /// Get all shares where user is the grantee
  Future<List<Share>> getSharedWithUser(String userEmail) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shares',
      where: 'grantee_email = ?',
      whereArgs: [userEmail],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _mapToShare(map)).toList();
  }

  /// Get shares for a specific subject (document or folder)
  Future<List<Share>> getSharesBySubjectId(String subjectId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shares',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _mapToShare(map)).toList();
  }

  /// Get a specific share by ID
  Future<Share?> getShareById(String shareId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shares',
      where: 'id = ?',
      whereArgs: [shareId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToShare(maps.first);
  }

  /// Insert a new share
  Future<void> insertShare(Share share) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'shares',
      _shareToMap(share),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing share
  Future<void> updateShare(Share share) async {
    final db = await _databaseHelper.database;
    await db.update(
      'shares',
      _shareToMap(share),
      where: 'id = ?',
      whereArgs: [share.id],
    );
  }

  /// Delete a share by ID
  Future<void> deleteShare(String shareId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'shares',
      where: 'id = ?',
      whereArgs: [shareId],
    );
  }

  /// Get all unsynced shares (for offline queue processing)
  Future<List<Share>> getUnsyncedShares() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shares',
      where: 'synced = ?',
      whereArgs: [0], // SQLite uses 0 for false
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => _mapToShare(map)).toList();
  }

  /// Mark share as synced
  Future<void> markShareAsSynced(String shareId) async {
    final db = await _databaseHelper.database;
    await db.update(
      'shares',
      {'synced': 1}, // SQLite uses 1 for true
      where: 'id = ?',
      whereArgs: [shareId],
    );
  }

  /// Mark share as unsynced (for conflict resolution)
  Future<void> markShareAsUnsynced(String shareId) async {
    final db = await _databaseHelper.database;
    await db.update(
      'shares',
      {'synced': 0}, // SQLite uses 0 for false
      where: 'id = ?',
      whereArgs: [shareId],
    );
  }

  /// Check if a specific subject is shared with a user
  Future<bool> isSharedWithUser(String subjectId, String userEmail) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'shares',
      where: 'subject_id = ? AND grantee_email = ?',
      whereArgs: [subjectId, userEmail],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Get share permission for a user on a subject
  Future<SharePermission?> getSharePermission(String subjectId, String userEmail) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shares',
      columns: ['permission'],
      where: 'subject_id = ? AND grantee_email = ?',
      whereArgs: [subjectId, userEmail],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final permissionString = maps.first['permission'] as String;
    return SharePermission.values.firstWhere((e) => e.name == permissionString);
  }

  /// Get shares count for a subject
  Future<int> getSharesCountBySubjectId(String subjectId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM shares WHERE subject_id = ?',
      [subjectId],
    );
    return result.first['count'] as int;
  }

  /// Convert database map to Share entity
  Share _mapToShare(Map<String, dynamic> map) {
    return Share(
      id: map['id'] as String,
      subjectId: map['subject_id'] as String,
      subjectType: ShareSubjectType.values.firstWhere((e) => e.name == map['subject_type']),
      ownerId: map['owner_id'] as String,
      granteeEmail: map['grantee_email'] as String?,
      permission: SharePermission.values.firstWhere((e) => e.name == map['permission']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Convert Share entity to database map
  Map<String, dynamic> _shareToMap(Share share) {
    return {
      'id': share.id,
      'subject_id': share.subjectId,
      'subject_type': share.subjectType.name,
      'owner_id': share.ownerId,
      'grantee_email': share.granteeEmail,
      'permission': share.permission.name,
      'created_at': share.createdAt.millisecondsSinceEpoch,
      'synced': 0, // Default to unsynced when inserting
    };
  }
}