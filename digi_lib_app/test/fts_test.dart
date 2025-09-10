import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:digi_lib_app/src/database/database_helper.dart';
import 'package:digi_lib_app/src/database/fts_helper.dart';
import 'package:digi_lib_app/src/database/database_constants.dart';
import 'package:digi_lib_app/src/services/local_search_service.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  group('FTS Helper Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.database; // Initialize database
    });

    tearDown(() async {
      await dbHelper.close();
      await dbHelper.deleteDatabase();
    });

    test('should initialize FTS table', () async {
      final isInitialized = await FTSHelper.isFTSInitialized();
      expect(isInitialized, isTrue);
    });

    test('should index document content', () async {
      final db = await dbHelper.database;
      
      // Insert test document
      await db.insert('documents', {
        'id': 'doc-1',
        'title': 'Test Document',
        'author': 'Test Author',
        'filename': 'test.pdf',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
        'updated_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      // Index content
      await FTSHelper.indexDocumentContent('doc-1', 'This is test content for searching');
      
      // Search for content
      final results = await FTSHelper.search('test content');
      expect(results.length, equals(1));
      expect(results.first.docId, equals('doc-1'));
    });

    test('should search with highlights', () async {
      final db = await dbHelper.database;
      
      // Insert test document
      await db.insert('documents', {
        'id': 'doc-1',
        'title': 'Flutter Development Guide',
        'author': 'John Doe',
        'filename': 'flutter_guide.pdf',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
        'updated_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      // Index content
      await FTSHelper.indexDocumentContent('doc-1', 'Flutter is a UI toolkit for building applications');
      
      // Search with highlights
      final results = await FTSHelper.searchWithHighlights('Flutter');
      expect(results.length, equals(1));
      expect(results.first.titleSnippet, contains('<mark>'));
    });

    test('should provide search suggestions', () async {
      final db = await dbHelper.database;
      
      // Insert test documents
      await db.insert('documents', {
        'id': 'doc-1',
        'title': 'Flutter Development',
        'author': 'John Doe',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
        'updated_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      await db.insert('documents', {
        'id': 'doc-2',
        'title': 'Flutter Testing',
        'author': 'Jane Smith',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
        'updated_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      // Get suggestions
      final suggestions = await FTSHelper.getSuggestions('Flu');
      expect(suggestions.length, greaterThan(0));
      expect(suggestions.any((s) => s.contains('Flutter')), isTrue);
    });

    test('should rebuild index', () async {
      final db = await dbHelper.database;
      
      // Insert test document
      await db.insert('documents', {
        'id': 'doc-1',
        'title': 'Test Document',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
        'updated_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      // Rebuild index
      await FTSHelper.rebuildIndex();
      
      // Verify document is indexed
      final results = await FTSHelper.search('Test');
      expect(results.length, equals(1));
    });

    test('should get statistics', () async {
      final db = await dbHelper.database;
      
      // Insert test document
      await db.insert('documents', {
        'id': 'doc-1',
        'title': 'Test Document',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
        'updated_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      await FTSHelper.rebuildIndex();
      
      final stats = await FTSHelper.getStatistics();
      expect(stats['total_documents'], equals(1));
    });
  });

  group('Local Search Service Tests', () {
    late LocalSearchService searchService;
    late DatabaseHelper dbHelper;

    setUp(() async {
      searchService = LocalSearchService();
      dbHelper = DatabaseHelper.instance;
      await dbHelper.database; // Initialize database
    });

    tearDown(() async {
      await dbHelper.close();
      await dbHelper.deleteDatabase();
    });

    test('should search documents', () async {
      final db = await dbHelper.database;
      
      // Insert test documents
      await db.insert('documents', {
        'id': 'doc-1',
        'title': 'Flutter Development Guide',
        'author': 'John Doe',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
        'updated_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      await db.insert('documents', {
        'id': 'doc-2',
        'title': 'React Development',
        'author': 'Jane Smith',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
        'updated_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      await FTSHelper.rebuildIndex();
      
      // Search for Flutter
      final results = await searchService.searchDocuments('Flutter');
      expect(results.results.length, equals(1));
      expect(results.results.first.title, contains('Flutter'));
    });

    test('should handle empty search query', () async {
      final results = await searchService.searchDocuments('');
      expect(results.isEmpty, isTrue);
    });

    test('should get search suggestions', () async {
      final db = await dbHelper.database;
      
      // Insert test document
      await db.insert('documents', {
        'id': 'doc-1',
        'title': 'Flutter Development',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
        'updated_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      final suggestions = await searchService.getSearchSuggestions('Flu');
      expect(suggestions, isA<List<String>>());
    });

    test('should save and retrieve search history', () async {
      await searchService.saveSearchToHistory('Flutter development');
      await searchService.saveSearchToHistory('React testing');
      
      final history = await searchService.getSearchHistory();
      expect(history.length, equals(2));
      expect(history, contains('Flutter development'));
      expect(history, contains('React testing'));
    });

    test('should clear search history', () async {
      await searchService.saveSearchToHistory('Test query');
      await searchService.clearSearchHistory();
      
      final history = await searchService.getSearchHistory();
      expect(history.isEmpty, isTrue);
    });

    test('should check if search index is ready', () async {
      final isReady = await searchService.isSearchIndexReady();
      expect(isReady, isTrue);
    });

    test('should get index statistics', () async {
      final db = await dbHelper.database;
      
      // Insert test document
      await db.insert('documents', {
        'id': 'doc-1',
        'title': 'Test Document',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
        'updated_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      await FTSHelper.rebuildIndex();
      
      final stats = await searchService.getIndexStatistics();
      expect(stats.totalDocuments, equals(1));
    });

    test('should handle search with filters', () async {
      final db = await dbHelper.database;
      
      // Insert test library
      await db.insert('libraries', {
        'id': 'lib-1',
        'name': 'Test Library',
        'type': 'local',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      // Insert test document
      await db.insert('documents', {
        'id': 'doc-1',
        'library_id': 'lib-1',
        'title': 'Flutter Guide',
        'created_at': DatabaseUtils.getCurrentTimestamp(),
        'updated_at': DatabaseUtils.getCurrentTimestamp(),
      });
      
      await FTSHelper.rebuildIndex();
      
      // Search with library filter
      final filters = LocalSearchFilters(libraryIds: ['lib-1']);
      final results = await searchService.searchDocuments('Flutter', filters: filters);
      
      expect(results.results.length, equals(1));
      expect(results.results.first.libraryId, equals('lib-1'));
    });

    test('should handle pagination', () async {
      final db = await dbHelper.database;
      
      // Insert multiple test documents
      for (int i = 1; i <= 25; i++) {
        await db.insert('documents', {
          'id': 'doc-$i',
          'title': 'Test Document $i',
          'created_at': DatabaseUtils.getCurrentTimestamp(),
          'updated_at': DatabaseUtils.getCurrentTimestamp(),
        });
      }
      
      await FTSHelper.rebuildIndex();
      
      // Search with pagination
      final results = await searchService.searchDocuments('Test', page: 1, limit: 10);
      
      expect(results.results.length, equals(10));
      expect(results.pagination.page, equals(1));
      expect(results.pagination.totalResults, equals(25));
      expect(results.pagination.totalPages, equals(3));
      expect(results.pagination.hasNextPage, isTrue);
    });
  });

  group('Search Models Tests', () {
    test('should create FTSSearchResult from map', () {
      final map = {
        'doc_id': 'doc-1',
        'title': 'Test Document',
        'author': 'Test Author',
        'rank': 0.5,
        'snippet': 'Test <mark>content</mark>',
      };
      
      final result = FTSSearchResult.fromMap(map);
      expect(result.docId, equals('doc-1'));
      expect(result.title, equals('Test Document'));
      expect(result.author, equals('Test Author'));
      expect(result.rank, equals(0.5));
      expect(result.snippet, equals('Test <mark>content</mark>'));
    });

    test('should create SearchPagination correctly', () {
      final pagination = SearchPagination(page: 2, limit: 10, totalResults: 25);
      
      expect(pagination.page, equals(2));
      expect(pagination.limit, equals(10));
      expect(pagination.totalResults, equals(25));
      expect(pagination.totalPages, equals(3));
      expect(pagination.offset, equals(10));
      expect(pagination.hasNextPage, isTrue);
      expect(pagination.hasPreviousPage, isTrue);
      expect(pagination.startIndex, equals(11));
      expect(pagination.endIndex, equals(20));
    });

    test('should handle empty search results', () {
      final results = LocalSearchResults.empty();
      
      expect(results.isEmpty, isTrue);
      expect(results.isNotEmpty, isFalse);
      expect(results.length, equals(0));
      expect(results.query, equals(''));
    });
  });
}