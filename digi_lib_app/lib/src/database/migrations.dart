import 'package:sqflite/sqflite.dart';

/// Database migration system for handling schema updates
class DatabaseMigrations {
  /// Map of migration functions by version
  static const Map<int, Future<void> Function(Database)> _migrations = {
    // Add future migrations here
    // 2: _migrateToV2,
    // 3: _migrateToV3,
  };
  
  /// Execute migration to a specific version
  static Future<void> migrateToVersion(Database db, int version) async {
    final migration = _migrations[version];
    if (migration != null) {
      await migration(db);
    }
  }
  
  /// Get all available migration versions
  static List<int> get availableVersions => _migrations.keys.toList()..sort();
  
  /// Check if a migration exists for the given version
  static bool hasMigration(int version) => _migrations.containsKey(version);
  
  // Example migration functions (commented out for now)
  
  // /// Migration to version 2 - Example: Add new column
  // static Future<void> _migrateToV2(Database db) async {
  //   await db.execute('ALTER TABLE documents ADD COLUMN new_field TEXT');
  //   await db.execute('CREATE INDEX idx_documents_new_field ON documents(new_field)');
  // }
  
  // /// Migration to version 3 - Example: Add new table
  // static Future<void> _migrateToV3(Database db) async {
  //   await db.execute('''
  //     CREATE TABLE new_table (
  //       id TEXT PRIMARY KEY,
  //       name TEXT NOT NULL,
  //       created_at INTEGER NOT NULL
  //     )
  //   ''');
  //   await db.execute('CREATE INDEX idx_new_table_name ON new_table(name)');
  // }
}

/// Database schema validation utilities
class SchemaValidator {
  /// Validate that all required tables exist
  static Future<bool> validateSchema(Database db) async {
    final requiredTables = [
      'users',
      'libraries', 
      'documents',
      'pages',
      'tags',
      'document_tags',
      'bookmarks',
      'comments',
      'shares',
      'reading_progress',
      'jobs_queue',
      'cache_metadata',
    ];
    
    for (final table in requiredTables) {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [table],
      );
      if (result.isEmpty) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Get list of all tables in the database
  static Future<List<String>> getTables(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    return result.map((row) => row['name'] as String).toList();
  }
  
  /// Get list of all indexes in the database
  static Future<List<String>> getIndexes(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'",
    );
    return result.map((row) => row['name'] as String).toList();
  }
  
  /// Get table schema information
  static Future<List<Map<String, dynamic>>> getTableInfo(Database db, String tableName) async {
    return await db.rawQuery('PRAGMA table_info($tableName)');
  }
  
  /// Check if a specific table exists
  static Future<bool> tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }
  
  /// Check if a specific index exists
  static Future<bool> indexExists(Database db, String indexName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index' AND name=?",
      [indexName],
    );
    return result.isNotEmpty;
  }
}