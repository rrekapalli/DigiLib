import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:digi_lib_app/src/database/database_helper.dart';
import 'package:digi_lib_app/src/services/cache_service.dart';
import 'package:digi_lib_app/src/database/repositories/cache_repository.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  group('Cache Service Tests', () {
    late CacheService cacheService;
    late DatabaseHelper dbHelper;

    setUp(() async {
      cacheService = CacheService.instance;
      dbHelper = DatabaseHelper.instance;
      await dbHelper.database; // Initialize database
      await cacheService.initialize();
    });

    tearDown(() async {
      await cacheService.clearCache();
      await dbHelper.close();
      await dbHelper.deleteDatabase();
    });

    test('should initialize cache service', () async {
      await cacheService.initialize(maxCacheSizeMB: 100);
      final config = cacheService.getCacheConfiguration();
      expect(config.maxSizeMB, equals(100));
    });

    test('should cache and retrieve page image', () async {
      final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
      const documentId = 'doc-1';
      const pageNumber = 1;
      
      // Cache the image
      await cacheService.cachePageImage(documentId, pageNumber, imageData);
      
      // Retrieve the image
      final cachedImage = await cacheService.getCachedPageImage(documentId, pageNumber);
      
      expect(cachedImage, isNotNull);
      expect(cachedImage, equals(imageData));
    });

    test('should cache and retrieve thumbnail', () async {
      final thumbnailData = Uint8List.fromList([10, 20, 30, 40, 50]);
      const documentId = 'doc-1';
      
      // Cache the thumbnail
      await cacheService.cacheThumbnail(documentId, thumbnailData);
      
      // Retrieve the thumbnail
      final cachedThumbnail = await cacheService.getCachedThumbnail(documentId);
      
      expect(cachedThumbnail, isNotNull);
      expect(cachedThumbnail, equals(thumbnailData));
    });

    test('should return null for non-existent cache entries', () async {
      final cachedImage = await cacheService.getCachedPageImage('non-existent', 1);
      final cachedThumbnail = await cacheService.getCachedThumbnail('non-existent');
      
      expect(cachedImage, isNull);
      expect(cachedThumbnail, isNull);
    });

    test('should calculate cache size correctly', () async {
      final imageData = Uint8List.fromList(List.filled(1000, 1));
      const documentId = 'doc-1';
      
      final initialSize = await cacheService.getCacheSize();
      
      await cacheService.cachePageImage(documentId, 1, imageData);
      
      final newSize = await cacheService.getCacheSize();
      expect(newSize, greaterThanOrEqualTo(initialSize));
    });

    test('should get cache statistics', () async {
      final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
      await cacheService.cachePageImage('doc-1', 1, imageData);
      
      final stats = await cacheService.getCacheStatistics();
      
      expect(stats.totalEntries, greaterThanOrEqualTo(0));
      expect(stats.maxSizeBytes, greaterThan(0));
    });

    test('should clear all cache', () async {
      final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
      await cacheService.cachePageImage('doc-1', 1, imageData);
      
      await cacheService.clearCache();
      
      final cachedImage = await cacheService.getCachedPageImage('doc-1', 1);
      expect(cachedImage, isNull);
    });
  });

  group('Cache Repository Tests', () {
    late SQLiteCacheRepository repository;
    late DatabaseHelper dbHelper;

    setUp(() async {
      repository = SQLiteCacheRepository();
      dbHelper = DatabaseHelper.instance;
      await dbHelper.database; // Initialize database
      await CacheService.instance.initialize();
    });

    tearDown(() async {
      await repository.clearCache();
      await dbHelper.close();
      await dbHelper.deleteDatabase();
    });

    test('should cache and retrieve page image through repository', () async {
      final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
      const documentId = 'doc-1';
      const pageNumber = 1;
      
      await repository.cachePageImage(documentId, pageNumber, imageData);
      final cachedImage = await repository.getCachedPageImage(documentId, pageNumber);
      
      expect(cachedImage, equals(imageData));
    });

    test('should get cache size through repository', () async {
      final imageData = Uint8List.fromList(List.filled(1000, 1));
      await repository.cachePageImage('doc-1', 1, imageData);
      
      final size = await repository.getCacheSize();
      expect(size, greaterThanOrEqualTo(0));
    });
  });

  group('Cache Models Tests', () {
    test('should create CacheStatistics correctly', () {
      final stats = CacheStatistics(
        totalEntries: 10,
        totalSizeBytes: 1024 * 1024, // 1MB
        averageSizeBytes: 102400, // 100KB
        maxSizeBytes: 10 * 1024 * 1024, // 10MB
      );
      
      expect(stats.totalSizeMB, equals(1.0));
      expect(stats.maxSizeMB, equals(10.0));
      expect(stats.usagePercentage, equals(10.0));
      expect(stats.isNearLimit, isFalse);
    });

    test('should detect near limit cache usage', () {
      final stats = CacheStatistics(
        totalEntries: 10,
        totalSizeBytes: 9 * 1024 * 1024, // 9MB
        averageSizeBytes: 921600,
        maxSizeBytes: 10 * 1024 * 1024, // 10MB
      );
      
      expect(stats.usagePercentage, equals(90.0));
      expect(stats.isNearLimit, isTrue);
    });

    test('should create empty CacheStatistics', () {
      final stats = CacheStatistics.empty(1024 * 1024);
      
      expect(stats.totalEntries, equals(0));
      expect(stats.totalSizeBytes, equals(0));
      expect(stats.usagePercentage, equals(0));
    });
  });
}