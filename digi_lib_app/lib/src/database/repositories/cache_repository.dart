import 'dart:typed_data';
import 'package:digi_lib_app/src/database/database_helper.dart';
import 'package:digi_lib_app/src/database/database_constants.dart';
import 'package:digi_lib_app/src/services/cache_service.dart';

/// Repository interface for cache operations
abstract class CacheRepository {
  Future<void> cachePageImage(String documentId, int page, Uint8List imageData);
  Future<Uint8List?> getCachedPageImage(String documentId, int page);
  Future<void> cacheThumbnail(String documentId, Uint8List thumbnailData);
  Future<Uint8List?> getCachedThumbnail(String documentId);
  Future<void> evictLRU(int targetSizeBytes);
  Future<int> getCacheSize();
  Future<List<CacheEntry>> getLRUEntries(int limit);
  Future<void> clearCache();
}

/// SQLite implementation of CacheRepository
class SQLiteCacheRepository implements CacheRepository {
  final CacheService _cacheService = CacheService.instance;
  
  @override
  Future<void> cachePageImage(String documentId, int page, Uint8List imageData) async {
    await _cacheService.cachePageImage(documentId, page, imageData);
  }
  
  @override
  Future<Uint8List?> getCachedPageImage(String documentId, int page) async {
    return await _cacheService.getCachedPageImage(documentId, page);
  }
  
  @override
  Future<void> cacheThumbnail(String documentId, Uint8List thumbnailData) async {
    await _cacheService.cacheThumbnail(documentId, thumbnailData);
  }
  
  @override
  Future<Uint8List?> getCachedThumbnail(String documentId) async {
    return await _cacheService.getCachedThumbnail(documentId);
  }
  
  @override
  Future<void> evictLRU(int targetSizeBytes) async {
    final currentSize = await getCacheSize();
    if (currentSize <= targetSizeBytes) return;
    
    final db = await DatabaseHelper.instance.database;
    final sizeToRemove = currentSize - targetSizeBytes;
    
    // Get LRU entries
    final entries = await db.query(
      DatabaseConstants.cacheMetadataTable,
      orderBy: '${DatabaseConstants.cacheLastAccessedColumn} ASC',
    );
    
    int removedSize = 0;
    for (final entry in entries) {
      if (removedSize >= sizeToRemove) break;
      
      final cacheKey = entry[DatabaseConstants.cacheKeyColumn] as String;
      final entrySize = entry[DatabaseConstants.cacheSizeBytesColumn] as int;
      
      await _removeCacheEntry(cacheKey);
      removedSize += entrySize;
    }
  }
  
  @override
  Future<int> getCacheSize() async {
    return await _cacheService.getCacheSize();
  }
  
  @override
  Future<List<CacheEntry>> getLRUEntries(int limit) async {
    final db = await DatabaseHelper.instance.database;
    
    final results = await db.query(
      DatabaseConstants.cacheMetadataTable,
      orderBy: '${DatabaseConstants.cacheLastAccessedColumn} ASC',
      limit: limit,
    );
    
    return results.map((row) => CacheEntry.fromMap(row)).toList();
  }
  
  @override
  Future<void> clearCache() async {
    await _cacheService.clearCache();
  }
  
  /// Remove a cache entry
  Future<void> _removeCacheEntry(String cacheKey) async {
    final db = await DatabaseHelper.instance.database;
    
    await db.delete(
      DatabaseConstants.cacheMetadataTable,
      where: '${DatabaseConstants.cacheKeyColumn} = ?',
      whereArgs: [cacheKey],
    );
  }
}

/// Cache preloader for warming cache with frequently accessed content
class CachePreloader {
  final CacheRepository _cacheRepository;
  
  CachePreloader(this._cacheRepository);
  
  /// Preload pages for a document
  Future<void> preloadDocumentPages(
    String documentId,
    List<int> pageNumbers,
    Future<Uint8List> Function(String documentId, int pageNumber) pageRenderer,
  ) async {
    for (final pageNumber in pageNumbers) {
      try {
        // Check if already cached
        final cached = await _cacheRepository.getCachedPageImage(documentId, pageNumber);
        if (cached == null) {
          // Render and cache
          final imageData = await pageRenderer(documentId, pageNumber);
          await _cacheRepository.cachePageImage(documentId, pageNumber, imageData);
        }
      } catch (e) {
        // Continue with other pages if one fails
        continue;
      }
    }
  }
  
  /// Preload thumbnails for multiple documents
  Future<void> preloadThumbnails(
    List<String> documentIds,
    Future<Uint8List> Function(String documentId) thumbnailRenderer,
  ) async {
    for (final documentId in documentIds) {
      try {
        // Check if already cached
        final cached = await _cacheRepository.getCachedThumbnail(documentId);
        if (cached == null) {
          // Render and cache
          final thumbnailData = await thumbnailRenderer(documentId);
          await _cacheRepository.cacheThumbnail(documentId, thumbnailData);
        }
      } catch (e) {
        // Continue with other documents if one fails
        continue;
      }
    }
  }
  
  /// Warm cache based on user reading patterns
  Future<void> warmCacheFromReadingHistory(
    List<String> recentDocumentIds,
    Future<Uint8List> Function(String documentId, int pageNumber) pageRenderer,
  ) async {
    for (final documentId in recentDocumentIds.take(10)) {
      try {
        // Preload first 3 pages of recently accessed documents
        await preloadDocumentPages(
          documentId,
          [1, 2, 3],
          pageRenderer,
        );
      } catch (e) {
        continue;
      }
    }
  }
}

/// Cache manager for coordinating cache operations
class CacheManager {
  final CacheRepository _repository;
  final CachePreloader _preloader;
  final CacheService _cacheService = CacheService.instance;
  
  CacheManager(this._repository) : _preloader = CachePreloader(_repository);
  
  /// Initialize cache manager
  Future<void> initialize({
    int? maxCacheSizeMB,
    Duration? cacheExpiry,
  }) async {
    await _cacheService.initialize(
      maxCacheSizeMB: maxCacheSizeMB,
      cacheExpiry: cacheExpiry,
    );
  }
  
  /// Get cache statistics
  Future<CacheStatistics> getStatistics() async {
    return await _cacheService.getCacheStatistics();
  }
  
  /// Optimize cache by removing least recently used entries
  Future<void> optimizeCache({int? targetSizeMB}) async {
    final stats = await getStatistics();
    final targetSizeBytes = targetSizeMB != null 
        ? targetSizeMB * 1024 * 1024
        : (stats.maxSizeBytes * 0.8).round(); // 80% of max size
    
    if (stats.totalSizeBytes > targetSizeBytes) {
      await _repository.evictLRU(targetSizeBytes);
    }
  }
  
  /// Schedule cache maintenance
  Future<void> performMaintenance() async {
    try {
      // Clean up expired entries
      await _cleanupExpiredEntries();
      
      // Optimize cache size
      await optimizeCache();
      
      // Validate cache integrity
      await _validateCacheIntegrity();
    } catch (e) {
      // Log maintenance errors but don't throw
    }
  }
  
  /// Clean up expired cache entries
  Future<void> _cleanupExpiredEntries() async {
    final config = _cacheService.getCacheConfiguration();
    final expiryTime = DateTime.now().subtract(config.expiry);
    
    final db = await DatabaseHelper.instance.database;
    final expiredEntries = await db.query(
      DatabaseConstants.cacheMetadataTable,
      where: '${DatabaseConstants.createdAtColumn} < ?',
      whereArgs: [DatabaseUtils.dateTimeToTimestamp(expiryTime)],
    );
    
    for (final entry in expiredEntries) {
      final cacheKey = entry[DatabaseConstants.cacheKeyColumn] as String;
      await _removeCacheEntry(cacheKey);
    }
  }
  
  /// Validate cache integrity
  Future<void> _validateCacheIntegrity() async {
    final db = await DatabaseHelper.instance.database;
    final entries = await db.query(DatabaseConstants.cacheMetadataTable);
    
    for (final entry in entries) {
      final cacheKey = entry[DatabaseConstants.cacheKeyColumn] as String;
      final cacheEntry = await _cacheService.getCacheEntry(cacheKey);
      
      if (cacheEntry == null) {
        // Remove orphaned metadata
        await _removeCacheEntry(cacheKey);
      }
    }
  }
  
  /// Remove cache entry
  Future<void> _removeCacheEntry(String cacheKey) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      DatabaseConstants.cacheMetadataTable,
      where: '${DatabaseConstants.cacheKeyColumn} = ?',
      whereArgs: [cacheKey],
    );
  }
  
  /// Get preloader instance
  CachePreloader get preloader => _preloader;
  
  /// Clear all cache
  Future<void> clearAll() async {
    await _repository.clearCache();
  }
  
  /// Clear cache for specific document
  Future<void> clearDocument(String documentId) async {
    await _cacheService.clearDocumentCache(documentId);
  }
  
  /// Update cache configuration
  Future<void> updateConfiguration({
    int? maxSizeMB,
    Duration? expiry,
  }) async {
    await _cacheService.setCacheConfiguration(
      maxSizeMB: maxSizeMB,
      expiry: expiry,
    );
  }
  
  /// Get cache configuration
  CacheConfiguration getConfiguration() {
    return _cacheService.getCacheConfiguration();
  }
}