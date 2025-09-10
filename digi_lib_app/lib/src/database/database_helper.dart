import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'fts_helper.dart';

/// Database helper class for managing SQLite database operations
/// Handles database creation, migrations, and provides access to the database instance
class DatabaseHelper {
  static const String _databaseName = 'digi_lib.db';
  static const int _databaseVersion = 1;
  
  static Database? _database;
  static DatabaseHelper? _instance;
  static bool _configurationAttempted = false;
  
  DatabaseHelper._internal();
  
  /// Singleton instance of DatabaseHelper
  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }
  
  /// Get the database instance, creating it if necessary
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  /// Initialize the database
  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    // Get the database path
    String path;
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, _databaseName);
    } catch (e) {
      // Fallback for testing - use in-memory database
      path = inMemoryDatabasePath;
    }
    
    // Open the database
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }
  
  /// Configure database settings
  Future<void> _onConfigure(Database db) async {
    // Only attempt configuration once to avoid repeated errors
    if (_configurationAttempted) {
      return;
    }
    _configurationAttempted = true;
    
    try {
      // Enable foreign key constraints
      await db.execute('PRAGMA foreign_keys = ON');
      
      // Skip WAL mode on Android due to compatibility issues
      if (!Platform.isAndroid) {
        try {
          await db.execute('PRAGMA journal_mode = WAL');
        } catch (e) {
          debugPrint('WAL mode not supported, using default journal mode');
        }
      }
      
      // Set synchronous mode to NORMAL for better performance
      try {
        await db.execute('PRAGMA synchronous = NORMAL');
      } catch (e) {
        debugPrint('Could not set synchronous mode: $e');
      }
    } catch (e) {
      debugPrint('Error configuring database: $e');
      // Continue with database initialization even if configuration fails
    }
  }
  
  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _createIndexes(db);
    await FTSHelper.initializeFTS(db);
  }
  
  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      await _migrateToVersion(db, version);
    }
  }
  
  /// Create all database tables
  Future<void> _createTables(Database db) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        name TEXT,
        provider TEXT,
        provider_id TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    
    // Libraries table
    await db.execute('''
      CREATE TABLE libraries (
        id TEXT PRIMARY KEY,
        owner_id TEXT REFERENCES users(id) ON DELETE SET NULL,
        name TEXT NOT NULL,
        type TEXT CHECK(type IN ('local','gdrive','onedrive','s3')) NOT NULL,
        config TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    
    // Documents table
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        library_id TEXT REFERENCES libraries(id) ON DELETE CASCADE,
        title TEXT,
        author TEXT,
        filename TEXT,
        relative_path TEXT,
        full_path TEXT,
        extension TEXT,
        renamed_name TEXT,
        isbn TEXT,
        year_published INTEGER,
        status TEXT,
        cloud_id TEXT,
        sha256 TEXT,
        size_bytes INTEGER,
        page_count INTEGER,
        format TEXT,
        image_url TEXT,
        amazon_url TEXT,
        review_url TEXT,
        metadata_json TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        synced_at INTEGER
      )
    ''');
    
    // Pages table
    await db.execute('''
      CREATE TABLE pages (
        id TEXT PRIMARY KEY,
        doc_id TEXT REFERENCES documents(id) ON DELETE CASCADE,
        page_number INTEGER NOT NULL,
        text_content TEXT,
        thumbnail_url TEXT,
        created_at INTEGER NOT NULL,
        UNIQUE (doc_id, page_number)
      )
    ''');
    
    // Tags table
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        owner_id TEXT REFERENCES users(id) ON DELETE SET NULL,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        UNIQUE(owner_id, name)
      )
    ''');
    
    // Document tags junction table
    await db.execute('''
      CREATE TABLE document_tags (
        id TEXT PRIMARY KEY,
        doc_id TEXT REFERENCES documents(id) ON DELETE CASCADE,
        tag_id TEXT REFERENCES tags(id) ON DELETE CASCADE,
        created_at INTEGER NOT NULL,
        UNIQUE (doc_id, tag_id)
      )
    ''');
    
    // Bookmarks table
    await db.execute('''
      CREATE TABLE bookmarks (
        id TEXT PRIMARY KEY,
        user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
        doc_id TEXT REFERENCES documents(id) ON DELETE CASCADE,
        page_number INTEGER,
        note TEXT,
        created_at INTEGER NOT NULL,
        synced BOOLEAN DEFAULT FALSE
      )
    ''');
    
    // Comments table
    await db.execute('''
      CREATE TABLE comments (
        id TEXT PRIMARY KEY,
        doc_id TEXT REFERENCES documents(id) ON DELETE CASCADE,
        user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
        page_number INTEGER,
        anchor TEXT,
        content TEXT,
        created_at INTEGER NOT NULL,
        synced BOOLEAN DEFAULT FALSE
      )
    ''');
    
    // Shares table
    await db.execute('''
      CREATE TABLE shares (
        id TEXT PRIMARY KEY,
        subject_id TEXT,
        subject_type TEXT CHECK(subject_type IN ('document','folder')),
        owner_id TEXT REFERENCES users(id) ON DELETE CASCADE,
        grantee_email TEXT,
        permission TEXT CHECK(permission IN ('view','comment','full')),
        created_at INTEGER NOT NULL,
        synced BOOLEAN DEFAULT FALSE
      )
    ''');
    
    // Reading progress table
    await db.execute('''
      CREATE TABLE reading_progress (
        user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
        doc_id TEXT REFERENCES documents(id) ON DELETE CASCADE,
        last_page INTEGER,
        updated_at INTEGER NOT NULL,
        synced BOOLEAN DEFAULT FALSE,
        PRIMARY KEY (user_id, doc_id)
      )
    ''');
    
    // Jobs queue for offline actions
    await db.execute('''
      CREATE TABLE jobs_queue (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        attempts INTEGER DEFAULT 0,
        last_error TEXT,
        scheduled_at INTEGER
      )
    ''');
    
    // Cache metadata table
    await db.execute('''
      CREATE TABLE cache_metadata (
        key TEXT PRIMARY KEY,
        size_bytes INTEGER NOT NULL,
        last_accessed INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    
    // Saved searches table
    await db.execute('''
      CREATE TABLE saved_searches (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        query TEXT NOT NULL,
        filters TEXT,
        created_at INTEGER NOT NULL,
        last_used_at INTEGER,
        use_count INTEGER DEFAULT 0
      )
    ''');
    
    // Search analytics table
    await db.execute('''
      CREATE TABLE search_analytics (
        query TEXT PRIMARY KEY,
        search_count INTEGER NOT NULL DEFAULT 1,
        first_searched INTEGER NOT NULL,
        last_searched INTEGER NOT NULL,
        total_results INTEGER NOT NULL DEFAULT 0,
        avg_result_count REAL NOT NULL DEFAULT 0.0
      )
    ''');
    
    // Sync metadata table for tracking sync state
    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }
  
  /// Create database indexes for performance optimization
  Future<void> _createIndexes(Database db) async {
    // Documents indexes
    await db.execute('CREATE INDEX idx_documents_library_id ON documents(library_id)');
    await db.execute('CREATE INDEX idx_documents_title ON documents(title)');
    await db.execute('CREATE INDEX idx_documents_author ON documents(author)');
    await db.execute('CREATE INDEX idx_documents_updated_at ON documents(updated_at)');
    await db.execute('CREATE INDEX idx_documents_synced_at ON documents(synced_at)');
    
    // Pages indexes
    await db.execute('CREATE INDEX idx_pages_doc_id ON pages(doc_id)');
    await db.execute('CREATE INDEX idx_pages_doc_page ON pages(doc_id, page_number)');
    
    // Bookmarks indexes
    await db.execute('CREATE INDEX idx_bookmarks_user_doc ON bookmarks(user_id, doc_id)');
    await db.execute('CREATE INDEX idx_bookmarks_synced ON bookmarks(synced)');
    
    // Comments indexes
    await db.execute('CREATE INDEX idx_comments_doc_id ON comments(doc_id)');
    await db.execute('CREATE INDEX idx_comments_synced ON comments(synced)');
    
    // Reading progress indexes
    await db.execute('CREATE INDEX idx_reading_progress_user ON reading_progress(user_id)');
    await db.execute('CREATE INDEX idx_reading_progress_synced ON reading_progress(synced)');
    
    // Jobs queue indexes
    await db.execute('CREATE INDEX idx_jobs_queue_status ON jobs_queue(status)');
    await db.execute('CREATE INDEX idx_jobs_queue_scheduled ON jobs_queue(scheduled_at)');
    
    // Cache metadata indexes
    await db.execute('CREATE INDEX idx_cache_metadata_last_accessed ON cache_metadata(last_accessed)');
    
    // Document tags indexes
    await db.execute('CREATE INDEX idx_document_tags_doc_id ON document_tags(doc_id)');
    await db.execute('CREATE INDEX idx_document_tags_tag_id ON document_tags(tag_id)');
    
    // Tags indexes
    await db.execute('CREATE INDEX idx_tags_owner_id ON tags(owner_id)');
    await db.execute('CREATE INDEX idx_tags_name ON tags(name)');
    
    // Shares indexes
    await db.execute('CREATE INDEX idx_shares_owner_id ON shares(owner_id)');
    await db.execute('CREATE INDEX idx_shares_subject_id ON shares(subject_id)');
    await db.execute('CREATE INDEX idx_shares_synced ON shares(synced)');
    
    // Saved searches indexes
    await db.execute('CREATE INDEX idx_saved_searches_name ON saved_searches(name)');
    await db.execute('CREATE INDEX idx_saved_searches_last_used ON saved_searches(last_used_at)');
    await db.execute('CREATE INDEX idx_saved_searches_use_count ON saved_searches(use_count)');
    
    // Search analytics indexes
    await db.execute('CREATE INDEX idx_search_analytics_count ON search_analytics(search_count)');
    await db.execute('CREATE INDEX idx_search_analytics_last_searched ON search_analytics(last_searched)');
  }
  
  /// Handle database migration to a specific version
  Future<void> _migrateToVersion(Database db, int version) async {
    switch (version) {
      case 1:
        // Initial version - no migration needed
        break;
      // Add future migration cases here
      default:
        throw Exception('Unknown database version: $version');
    }
  }
  
  /// Close the database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      _configurationAttempted = false;
    }
  }
  
  /// Delete the database file (for testing purposes)
  Future<void> deleteDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore errors for in-memory databases or when path provider fails
    }
    _database = null;
    _configurationAttempted = false;
  }
  
  /// Get database file size in bytes
  Future<int> getDatabaseSize() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      // Return 0 for in-memory databases or when path provider fails
    }
    return 0;
  }
  
  /// Execute a raw SQL query
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }
  
  /// Execute a raw SQL statement
  Future<int> rawExecute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }
  
  /// Encode a Map to JSON string for database storage
  String encodeJson(Map<String, dynamic> data) {
    return jsonEncode(data);
  }
  
  /// Decode a JSON string to Map from database
  Map<String, dynamic> decodeJson(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}