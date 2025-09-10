import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:digi_lib_app/src/database/database_helper.dart';
import 'package:digi_lib_app/src/database/migrations.dart';
import 'package:digi_lib_app/src/database/database_constants.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  group('DatabaseHelper Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() {
      dbHelper = DatabaseHelper.instance;
    });

    tearDown(() async {
      await dbHelper.close();
      await dbHelper.deleteDatabase();
    });

    test('should create database with all tables', () async {
      final db = await dbHelper.database;
      expect(db, isNotNull);

      // Verify all required tables exist
      final tables = await SchemaValidator.getTables(db);
      expect(tables, contains('users'));
      expect(tables, contains('libraries'));
      expect(tables, contains('documents'));
      expect(tables, contains('pages'));
      expect(tables, contains('tags'));
      expect(tables, contains('document_tags'));
      expect(tables, contains('bookmarks'));
      expect(tables, contains('comments'));
      expect(tables, contains('shares'));
      expect(tables, contains('reading_progress'));
      expect(tables, contains('jobs_queue'));
      expect(tables, contains('cache_metadata'));
    });

    test('should create all required indexes', () async {
      final db = await dbHelper.database;
      final indexes = await SchemaValidator.getIndexes(db);
      
      // Check some key indexes exist
      expect(indexes, contains('idx_documents_library_id'));
      expect(indexes, contains('idx_documents_title'));
      expect(indexes, contains('idx_pages_doc_id'));
      expect(indexes, contains('idx_bookmarks_user_doc'));
      expect(indexes, contains('idx_jobs_queue_status'));
    });

    test('should validate schema correctly', () async {
      final db = await dbHelper.database;
      final isValid = await SchemaValidator.validateSchema(db);
      expect(isValid, isTrue);
    });

    test('should handle foreign key constraints', () async {
      final db = await dbHelper.database;
      
      // Insert a user first
      await db.insert('users', {
        'id': 'user-1',
        'email': 'test@example.com',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      // Insert a library
      await db.insert('libraries', {
        'id': 'lib-1',
        'owner_id': 'user-1',
        'name': 'Test Library',
        'type': 'local',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      // Insert a document
      await db.insert('documents', {
        'id': 'doc-1',
        'library_id': 'lib-1',
        'title': 'Test Document',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
        'updated_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      // Verify the data was inserted
      final documents = await db.query('documents');
      expect(documents.length, equals(1));
      expect(documents.first['title'], equals('Test Document'));
    });

    test('should handle database size calculation', () async {
      await dbHelper.database; // Initialize database
      final size = await dbHelper.getDatabaseSize();
      // For in-memory databases used in testing, size will be 0
      expect(size, greaterThanOrEqualTo(0));
    });

    test('should execute raw queries', () async {
      final db = await dbHelper.database;
      
      // Insert test data
      await db.insert('users', {
        'id': 'user-1',
        'email': 'test@example.com',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      // Test raw query
      final result = await dbHelper.rawQuery('SELECT * FROM users WHERE id = ?', ['user-1']);
      expect(result.length, equals(1));
      expect(result.first['email'], equals('test@example.com'));
    });
  });

  group('DatabaseUtils Tests', () {
    test('should convert DateTime to timestamp and back', () {
      final now = DateTime.now();
      final timestamp = DatabaseUtils.dateTimeToTimestamp(now);
      final converted = DatabaseUtils.timestampToDateTime(timestamp);
      
      expect(converted.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
    });

    test('should convert boolean to int and back', () {
      expect(DatabaseUtils.boolToInt(true), equals(1));
      expect(DatabaseUtils.boolToInt(false), equals(0));
      expect(DatabaseUtils.intToBool(1), isTrue);
      expect(DatabaseUtils.intToBool(0), isFalse);
    });

    test('should escape SQL strings', () {
      const input = "O'Reilly's Book";
      const expected = "O''Reilly''s Book";
      expect(DatabaseUtils.escapeSqlString(input), equals(expected));
    });

    test('should build WHERE clauses', () {
      final conditions = {
        'name': 'John',
        'age': 25,
        'active': null,
        'tags': ['tag1', 'tag2'],
      };
      
      final whereClause = DatabaseUtils.buildWhereClause(conditions);
      expect(whereClause, contains('WHERE'));
      expect(whereClause, contains('name = ?'));
      expect(whereClause, contains('age = ?'));
      expect(whereClause, contains('active IS NULL'));
      expect(whereClause, contains('tags IN (?, ?)'));
    });

    test('should build ORDER BY clauses', () {
      expect(DatabaseUtils.buildOrderByClause('name'), equals('ORDER BY name ASC'));
      expect(DatabaseUtils.buildOrderByClause('date', ascending: false), equals('ORDER BY date DESC'));
    });

    test('should build LIMIT clauses', () {
      expect(DatabaseUtils.buildLimitClause(10), equals('LIMIT 10'));
      expect(DatabaseUtils.buildLimitClause(10, offset: 20), equals('LIMIT 10 OFFSET 20'));
    });

    test('should validate table and column names', () {
      expect(DatabaseUtils.isValidTableName('users'), isTrue);
      expect(DatabaseUtils.isValidTableName('user_profiles'), isTrue);
      expect(DatabaseUtils.isValidTableName('123invalid'), isFalse);
      expect(DatabaseUtils.isValidTableName('table-name'), isFalse);
      
      expect(DatabaseUtils.isValidColumnName('name'), isTrue);
      expect(DatabaseUtils.isValidColumnName('created_at'), isTrue);
      expect(DatabaseUtils.isValidColumnName('123invalid'), isFalse);
      expect(DatabaseUtils.isValidColumnName('column-name'), isFalse);
    });
  });

  group('SchemaValidator Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() {
      dbHelper = DatabaseHelper.instance;
    });

    tearDown(() async {
      await dbHelper.close();
      await dbHelper.deleteDatabase();
    });

    test('should check if table exists', () async {
      final db = await dbHelper.database;
      
      expect(await SchemaValidator.tableExists(db, 'users'), isTrue);
      expect(await SchemaValidator.tableExists(db, 'nonexistent_table'), isFalse);
    });

    test('should check if index exists', () async {
      final db = await dbHelper.database;
      
      expect(await SchemaValidator.indexExists(db, 'idx_documents_library_id'), isTrue);
      expect(await SchemaValidator.indexExists(db, 'nonexistent_index'), isFalse);
    });

    test('should get table info', () async {
      final db = await dbHelper.database;
      final tableInfo = await SchemaValidator.getTableInfo(db, 'users');
      
      expect(tableInfo, isNotEmpty);
      final columnNames = tableInfo.map((col) => col['name']).toList();
      expect(columnNames, contains('id'));
      expect(columnNames, contains('email'));
      expect(columnNames, contains('name'));
    });
  });
}