import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:digi_lib_app/src/database/database_helper.dart';
import 'package:digi_lib_app/src/database/database_constants.dart';

/// Cache service for managing file cache with LRU eviction policy
class CacheService {
  static const String _cacheDirectoryName = 'digi_lib_cache';
  static const String _pagesSubdir = 'pages';
  static const String _thumbnailsSubdir = 'thumbnails';
  static const String _documentsSubdir = 'documents';
  
  // Default cache settings
  static const int _defaultMaxCacheSizeMB = 500;
  static const int _maxCacheSizeMB = 2000;
  static const Duration _defaultCacheExpiry = Duration(days: 30);
  
  late Directory _cacheDirectory;
  late Directory _pagesDirectory;
  late Directory _thumbnailsDirectory;
  late Directory _documentsDirectory;
  
  int _maxCacheSizeBytes = _defaultMaxCacheSizeMB * 1024 * 1024;
  Duration _cacheExpiry = _defaultCacheExpiry;
  
  static CacheService? _instance;
  
  CacheService._internal();
  
  /// Singleton instance of CacheService
  static CacheService get instance {
    _instance ??= CacheService._internal();
    return _instance!;
  }
  
  /// Initialize the cache service
  Future<void> initialize({
    int? maxCacheSizeMB,
    Duration? cacheExpiry,
  }) async {
    if (maxCacheSizeMB != null) {
      _maxCacheSizeBytes = (maxCacheSizeMB.clamp(50, _maxCacheSizeMB) * 1024 * 1024);
    }
    
    if (cacheExpiry != null) {
      _cacheExpiry = cacheExpiry;
    }
    
    await _initializeCacheDirectories();
    await _cleanupExpiredCache();
  }
  
  /// Initialize cache directories
  Future<void> _initializeCacheDirectories() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory(join(appDir.path, _cacheDirectoryName));
      
      if (!await _cacheDirectory.exists()) {
        await _cacheDirectory.create(recursive: true);
      }
      
      _pagesDirectory = Directory(join(_cacheDirectory.path, _pagesSubdir));
      _thumbnailsDirectory = Directory(join(_cacheDirectory.path, _thumbnailsSubdir));
      _documentsDirectory = Directory(join(_cacheDirectory.path, _documentsSubdir));
      
      await _pagesDirectory.create(recursive: true);
      await _thumbnailsDirectory.create(recursive: true);
      await _documentsDirectory.create(recursive: true);
    } catch (e) {
      // Fallback to temporary directory for testing
      _cacheDirectory = Directory.systemTemp.createTempSync('digi_lib_cache');
      _pagesDirectory = Directory(join(_cacheDirectory.path, _pagesSubdir));
      _thumbnailsDirectory = Directory(join(_cacheDirectory.path, _thumbnailsSubdir));
      _documentsDirectory = Directory(join(_cacheDirectory.path, _documentsSubdir));
      
      await _pagesDirectory.create(recursive: true);
      await _thumbnailsDirectory.create(recursive: true);
      await _documentsDirectory.create(recursive: true);
    }
  }
  
  /// Cache a rendered page image
  Future<void> cachePageImage(
    String documentId,
    int pageNumber,
    Uint8List imageData, {
    String format = 'webp',
  }) async {
    final cacheKey = _generatePageCacheKey(documentId, pageNumber, format);
    final file = File(join(_pagesDirectory.path, '$cacheKey.$format'));
    
    try {
      await file.writeAsBytes(imageData);
      await _updateCacheMetadata(cacheKey, imageData.length);
      await _enforceCacheSizeLimit();
    } catch (e) {
      throw CacheException('Failed to cache page image: $e');
    }
  }
  
  /// Get cached page image
  Future<Uint8List?> getCachedPageImage(
    String documentId,
    int pageNumber, {
    String format = 'webp',
  }) async {
    final cacheKey = _generatePageCacheKey(documentId, pageNumber, format);
    final file = File(join(_pagesDirectory.path, '$cacheKey.$format'));
    
    try {
      if (await file.exists()) {
        await _updateCacheAccess(cacheKey);
        return await file.readAsBytes();
      }
    } catch (e) {
      // File might be corrupted, remove it
      await _removeCacheEntry(cacheKey);
    }
    
    return null;
  }
  
  /// Cache a document thumbnail
  Future<void> cacheThumbnail(
    String documentId,
    Uint8List thumbnailData, {
    String format = 'webp',
  }) async {
    final cacheKey = _generateThumbnailCacheKey(documentId, format);
    final file = File(join(_thumbnailsDirectory.path, '$cacheKey.$format'));
    
    try {
      await file.writeAsBytes(thumbnailData);
      await _updateCacheMetadata(cacheKey, thumbnailData.length);
      await _enforceCacheSizeLimit();
    } catch (e) {
      throw CacheException('Failed to cache thumbnail: $e');
    }
  }
  
  /// Get cached thumbnail
  Future<Uint8List?> getCachedThumbnail(
    String documentId, {
    String format = 'webp',
  }) async {
    final cacheKey = _generateThumbnailCacheKey(documentId, format);
    final file = File(join(_thumbnailsDirectory.path, '$cacheKey.$format'));
    
    try {
      if (await file.exists()) {
        await _updateCacheAccess(cacheKey);
        return await file.readAsBytes();
      }
    } catch (e) {
      await _removeCacheEntry(cacheKey);
    }
    
    return null;
  }
  
  /// Cache document metadata or content
  Future<void> cacheDocument(
    String documentId,
    Uint8List documentData,
    String filename,
  ) async {
    final cacheKey = _generateDocumentCacheKey(documentId, filename);
    final file = File(join(_documentsDirectory.path, cacheKey));
    
    try {
      await file.writeAsBytes(documentData);
      await _updateCacheMetadata(cacheKey, documentData.length);
      await _enforceCacheSizeLimit();
    } catch (e) {
      throw CacheException('Failed to cache document: $e');
    }
  }
  
  /// Get cached document
  Future<Uint8List?> getCachedDocument(
    String documentId,
    String filename,
  ) async {
    final cacheKey = _generateDocumentCacheKey(documentId, filename);
    final file = File(join(_documentsDirectory.path, cacheKey));
    
    try {
      if (await file.exists()) {
        await _updateCacheAccess(cacheKey);
        return await file.readAsBytes();
      }
    } catch (e) {
      await _removeCacheEntry(cacheKey);
    }
    
    return null;
  }
  
  /// Preload pages for a document
  Future<void> preloadPages(
    String documentId,
    List<int> pageNumbers,
    Future<Uint8List> Function(int pageNumber) pageRenderer,
  ) async {
    for (final pageNumber in pageNumbers) {
      try {
        // Check if page is already cached
        final cached = await getCachedPageImage(documentId, pageNumber);
        if (cached == null) {
          // Render and cache the page
          final imageData = await pageRenderer(pageNumber);
          await cachePageImage(documentId, pageNumber, imageData);
        }
      } catch (e) {
        // Continue with other pages if one fails
        continue;
      }
    }
  }
  
  /// Warm cache with frequently accessed content
  Future<void> warmCache(List<String> documentIds) async {
    for (final documentId in documentIds) {
      try {
        // Preload first few pages and thumbnail
        await preloadPages(documentId, [1, 2, 3], (pageNumber) async {
          // This would be implemented by the caller
          throw UnimplementedError('Page renderer not provided');
        });
      } catch (e) {
        // Continue with other documents
        continue;
      }
    }
  }
  
  /// Get current cache size in bytes
  Future<int> getCacheSize() async {
    final db = await DatabaseHelper.instance.database;
    
    try {
      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(size_bytes), 0) as total_size
        FROM cache_metadata
      ''');
      
      return result.first['total_size'] as int;
    } catch (e) {
      // Fallback to directory size calculation
      return await _calculateDirectorySize(_cacheDirectory);
    }
  }
  
  /// Get cache statistics
  Future<CacheStatistics> getCacheStatistics() async {
    final db = await DatabaseHelper.instance.database;
    
    try {
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_entries,
          COALESCE(SUM(size_bytes), 0) as total_size,
          AVG(size_bytes) as average_size,
          MIN(last_accessed) as oldest_access,
          MAX(last_accessed) as newest_access
        FROM cache_metadata
      ''');
      
      final row = result.first;
      return CacheStatistics(
        totalEntries: row['total_entries'] as int,
        totalSizeBytes: row['total_size'] as int,
        averageSizeBytes: (row['average_size'] as double?)?.round() ?? 0,
        oldestAccessTime: row['oldest_access'] != null 
            ? DatabaseUtils.timestampToDateTime(row['oldest_access'] as int)
            : null,
        newestAccessTime: row['newest_access'] != null
            ? DatabaseUtils.timestampToDateTime(row['newest_access'] as int)
            : null,
        maxSizeBytes: _maxCacheSizeBytes,
      );
    } catch (e) {
      return CacheStatistics.empty(_maxCacheSizeBytes);
    }
  }
  
  /// Clear all cache
  Future<void> clearCache() async {
    try {
      // Delete all cache files
      if (await _cacheDirectory.exists()) {
        await _cacheDirectory.delete(recursive: true);
        await _initializeCacheDirectories();
      }
      
      // Clear cache metadata
      final db = await DatabaseHelper.instance.database;
      await db.execute('DELETE FROM cache_metadata');
    } catch (e) {
      throw CacheException('Failed to clear cache: $e');
    }
  }
  
  /// Clear cache for a specific document
  Future<void> clearDocumentCache(String documentId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Get all cache entries for this document
      final entries = await db.query(
        'cache_metadata',
        where: 'key LIKE ?',
        whereArgs: ['$documentId%'],
      );
      
      // Delete files and metadata
      for (final entry in entries) {
        final cacheKey = entry['key'] as String;
        await _removeCacheEntry(cacheKey);
      }
    } catch (e) {
      throw CacheException('Failed to clear document cache: $e');
    }
  }
  
  /// Enforce cache size limit using LRU eviction
  Future<void> _enforceCacheSizeLimit() async {
    final currentSize = await getCacheSize();
    
    if (currentSize <= _maxCacheSizeBytes) {
      return;
    }
    
    final db = await DatabaseHelper.instance.database;
    
    try {
      // Get cache entries ordered by last access (LRU)
      final entries = await db.query(
        'cache_metadata',
        orderBy: 'last_accessed ASC',
      );
      
      int sizeToRemove = currentSize - _maxCacheSizeBytes;
      int removedSize = 0;
      
      for (final entry in entries) {
        if (removedSize >= sizeToRemove) break;
        
        final cacheKey = entry['key'] as String;
        final entrySize = entry['size_bytes'] as int;
        
        await _removeCacheEntry(cacheKey);
        removedSize += entrySize;
      }
    } catch (e) {
      throw CacheException('Failed to enforce cache size limit: $e');
    }
  }
  
  /// Clean up expired cache entries
  Future<void> _cleanupExpiredCache() async {
    final db = await DatabaseHelper.instance.database;
    final expiryTimestamp = DatabaseUtils.dateTimeToTimestamp(
      DateTime.now().subtract(_cacheExpiry),
    );
    
    try {
      // Get expired entries
      final expiredEntries = await db.query(
        'cache_metadata',
        where: 'created_at < ?',
        whereArgs: [expiryTimestamp],
      );
      
      // Remove expired entries
      for (final entry in expiredEntries) {
        final cacheKey = entry['key'] as String;
        await _removeCacheEntry(cacheKey);
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
  
  /// Update cache metadata for an entry
  Future<void> _updateCacheMetadata(String cacheKey, int sizeBytes) async {
    final db = await DatabaseHelper.instance.database;
    final timestamp = DatabaseUtils.getCurrentTimestamp();
    
    try {
      await db.execute('''
        INSERT OR REPLACE INTO cache_metadata (key, size_bytes, last_accessed, created_at)
        VALUES (?, ?, ?, COALESCE((SELECT created_at FROM cache_metadata WHERE key = ?), ?))
      ''', [cacheKey, sizeBytes, timestamp, cacheKey, timestamp]);
    } catch (e) {
      // Ignore metadata errors
    }
  }
  
  /// Update cache access time
  Future<void> _updateCacheAccess(String cacheKey) async {
    final db = await DatabaseHelper.instance.database;
    final timestamp = DatabaseUtils.getCurrentTimestamp();
    
    try {
      await db.execute('''
        UPDATE cache_metadata 
        SET last_accessed = ? 
        WHERE key = ?
      ''', [timestamp, cacheKey]);
    } catch (e) {
      // Ignore access update errors
    }
  }
  
  /// Remove a cache entry (file and metadata)
  Future<void> _removeCacheEntry(String cacheKey) async {
    try {
      // Remove file
      final possiblePaths = [
        join(_pagesDirectory.path, '$cacheKey.webp'),
        join(_pagesDirectory.path, '$cacheKey.png'),
        join(_pagesDirectory.path, '$cacheKey.jpg'),
        join(_thumbnailsDirectory.path, '$cacheKey.webp'),
        join(_thumbnailsDirectory.path, '$cacheKey.png'),
        join(_thumbnailsDirectory.path, '$cacheKey.jpg'),
        join(_documentsDirectory.path, cacheKey),
      ];
      
      for (final path in possiblePaths) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          break;
        }
      }
      
      // Remove metadata
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'cache_metadata',
        where: 'key = ?',
        whereArgs: [cacheKey],
      );
    } catch (e) {
      // Ignore removal errors
    }
  }
  
  /// Calculate directory size recursively
  Future<int> _calculateDirectorySize(Directory directory) async {
    int totalSize = 0;
    
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
    } catch (e) {
      // Return 0 if calculation fails
    }
    
    return totalSize;
  }
  
  /// Generate cache key for page images
  String _generatePageCacheKey(String documentId, int pageNumber, String format) {
    return '${documentId}_page_${pageNumber}_$format';
  }
  
  /// Generate cache key for thumbnails
  String _generateThumbnailCacheKey(String documentId, String format) {
    return '${documentId}_thumb_$format';
  }
  
  /// Generate cache key for documents
  String _generateDocumentCacheKey(String documentId, String filename) {
    final fileExtension = extension(filename);
    return '${documentId}_doc$fileExtension';
  }
  
  /// Check if cache entry exists
  Future<bool> isCached(String cacheKey) async {
    final db = await DatabaseHelper.instance.database;
    
    try {
      final result = await db.query(
        'cache_metadata',
        where: 'key = ?',
        whereArgs: [cacheKey],
        limit: 1,
      );
      
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Get cache entry info
  Future<CacheEntry?> getCacheEntry(String cacheKey) async {
    final db = await DatabaseHelper.instance.database;
    
    try {
      final result = await db.query(
        'cache_metadata',
        where: 'key = ?',
        whereArgs: [cacheKey],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return CacheEntry.fromMap(result.first);
      }
    } catch (e) {
      // Return null if query fails
    }
    
    return null;
  }
  
  /// Set cache configuration
  Future<void> setCacheConfiguration({
    int? maxSizeMB,
    Duration? expiry,
  }) async {
    if (maxSizeMB != null) {
      _maxCacheSizeBytes = (maxSizeMB.clamp(50, _maxCacheSizeMB) * 1024 * 1024);
      await _enforceCacheSizeLimit();
    }
    
    if (expiry != null) {
      _cacheExpiry = expiry;
      await _cleanupExpiredCache();
    }
  }
  
  /// Get cache configuration
  CacheConfiguration getCacheConfiguration() {
    return CacheConfiguration(
      maxSizeMB: (_maxCacheSizeBytes / (1024 * 1024)).round(),
      expiry: _cacheExpiry,
    );
  }
}

/// Cache statistics model
class CacheStatistics {
  final int totalEntries;
  final int totalSizeBytes;
  final int averageSizeBytes;
  final DateTime? oldestAccessTime;
  final DateTime? newestAccessTime;
  final int maxSizeBytes;
  
  CacheStatistics({
    required this.totalEntries,
    required this.totalSizeBytes,
    required this.averageSizeBytes,
    this.oldestAccessTime,
    this.newestAccessTime,
    required this.maxSizeBytes,
  });
  
  factory CacheStatistics.empty(int maxSizeBytes) {
    return CacheStatistics(
      totalEntries: 0,
      totalSizeBytes: 0,
      averageSizeBytes: 0,
      maxSizeBytes: maxSizeBytes,
    );
  }
  
  double get totalSizeMB => totalSizeBytes / (1024 * 1024);
  double get maxSizeMB => maxSizeBytes / (1024 * 1024);
  double get usagePercentage => maxSizeBytes > 0 ? (totalSizeBytes / maxSizeBytes) * 100 : 0;
  bool get isNearLimit => usagePercentage > 80;
}

/// Cache entry model
class CacheEntry {
  final String key;
  final int sizeBytes;
  final DateTime lastAccessed;
  final DateTime createdAt;
  
  CacheEntry({
    required this.key,
    required this.sizeBytes,
    required this.lastAccessed,
    required this.createdAt,
  });
  
  factory CacheEntry.fromMap(Map<String, dynamic> map) {
    return CacheEntry(
      key: map['key'] as String,
      sizeBytes: map['size_bytes'] as int,
      lastAccessed: DatabaseUtils.timestampToDateTime(map['last_accessed'] as int),
      createdAt: DatabaseUtils.timestampToDateTime(map['created_at'] as int),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'size_bytes': sizeBytes,
      'last_accessed': DatabaseUtils.dateTimeToTimestamp(lastAccessed),
      'created_at': DatabaseUtils.dateTimeToTimestamp(createdAt),
    };
  }
  
  Duration get age => DateTime.now().difference(createdAt);
  Duration get timeSinceLastAccess => DateTime.now().difference(lastAccessed);
}

/// Cache configuration model
class CacheConfiguration {
  final int maxSizeMB;
  final Duration expiry;
  
  CacheConfiguration({
    required this.maxSizeMB,
    required this.expiry,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'max_size_mb': maxSizeMB,
      'expiry_days': expiry.inDays,
    };
  }
}

/// Cache exception
class CacheException implements Exception {
  final String message;
  
  CacheException(this.message);
  
  @override
  String toString() => 'CacheException: $message';
}