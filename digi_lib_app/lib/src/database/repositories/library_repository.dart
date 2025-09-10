import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../models/entities/library.dart';
import '../database_helper.dart';

/// Repository for managing library data in local SQLite database
abstract class LibraryRepository {
  /// Find all libraries
  Future<List<Library>> findAll();
  
  /// Find library by ID
  Future<Library?> findById(String id);
  
  /// Save a library (insert or update)
  Future<void> save(Library library);
  
  /// Save multiple libraries
  Future<void> saveAll(List<Library> libraries);
  
  /// Delete a library by ID
  Future<void> delete(String id);
  
  /// Delete all libraries
  Future<void> deleteAll();
  
  /// Find libraries by type
  Future<List<Library>> findByType(LibraryType type);
  
  /// Find libraries by owner ID
  Future<List<Library>> findByOwnerId(String ownerId);
}

/// SQLite implementation of LibraryRepository
class LibraryRepositoryImpl implements LibraryRepository {
  final DatabaseHelper _databaseHelper;

  LibraryRepositoryImpl(this._databaseHelper);

  @override
  Future<List<Library>> findAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'libraries',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _mapToLibrary(map)).toList();
  }

  @override
  Future<Library?> findById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'libraries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return _mapToLibrary(maps.first);
  }

  @override
  Future<void> save(Library library) async {
    final db = await _databaseHelper.database;
    final map = _libraryToMap(library);

    await db.insert(
      'libraries',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveAll(List<Library> libraries) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();

    for (final library in libraries) {
      final map = _libraryToMap(library);
      batch.insert(
        'libraries',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<void> delete(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'libraries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteAll() async {
    final db = await _databaseHelper.database;
    await db.delete('libraries');
  }

  @override
  Future<List<Library>> findByType(LibraryType type) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'libraries',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _mapToLibrary(map)).toList();
  }

  @override
  Future<List<Library>> findByOwnerId(String ownerId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'libraries',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _mapToLibrary(map)).toList();
  }

  /// Convert database map to Library object
  Library _mapToLibrary(Map<String, dynamic> map) {
    return Library(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String?,
      name: map['name'] as String,
      type: LibraryType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => LibraryType.local,
      ),
      config: map['config'] != null 
          ? jsonDecode(map['config'] as String) as Map<String, dynamic>
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Convert Library object to database map
  Map<String, dynamic> _libraryToMap(Library library) {
    return {
      'id': library.id,
      'owner_id': library.ownerId,
      'name': library.name,
      'type': library.type.name,
      'config': library.config != null ? jsonEncode(library.config) : null,
      'created_at': library.createdAt.millisecondsSinceEpoch,
    };
  }
}