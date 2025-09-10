import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'performance_monitoring_service.dart';

/// Advanced network caching service with performance optimization
class NetworkCacheOptimizationService {
  static final Logger _logger = Logger('NetworkCacheOptimizationService');
  
  final PerformanceMonitoringService _performanceService;
  final Map<String, NetworkCacheEntry> _memoryCache = {};
  final Map<String, CacheMetadata> _cacheMetadata = {};
  
  Timer? _cleanupTimer;
  Timer? _statsTimer;
  
  // Configuration
  static const int maxMemoryCacheSize = 50 * 1024 * 1024; // 50MB
  static const int maxCacheEntries = 1000;
  static const Duration defaultTtl = Duration(minutes: 15);
  static const Duration cleanupInterval = Duration(minutes: 5);
  static const Duration statsInterval = Duration(minutes: 1);
  
  // Statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _cacheEvictions = 0;
  int _totalRequests = 0;
  
  final StreamController<CacheEvent> _eventController = 
      StreamController<CacheEvent>.broadcast();

  NetworkCacheOptimizationService(this._performanceService);

  /// Initialize the cache service
  Future<void> initialize() async {
    _logger.info('Initializing network cache optimization service');
    
    _startPeriodicCleanup();
    _startStatsReporting();
  }

  /// Start periodic cache cleanup
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(cleanupInterval, (timer) {
      _performCacheCleanup();
    });
  }

  /// Start periodic statistics reporting
  void _startStatsReporting() {
    _statsTimer = Timer.periodic(statsInterval, (timer) {
      _reportCacheStatistics();
    });
  }

  /// Get cached response or null if not found/expired
  Future<CachedResponse?> get(String key) async {
    _totalRequests++;
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final entry = _memoryCache[key];
      if (entry == null) {
        _cacheMisses++;
        stopwatch.stop();
        
        _performanceService.recordPerformanceMetric(
          PerformanceMetrics(
            operation: 'cache_miss',
            duration: stopwatch.elapsed,
            additionalData: {
              'cache_key': _hashKey(key),
              'cache_size': _memoryCache.length,
            },
            timestamp: DateTime.now(),
          ),
        );
        
        return null;
      }
      
      // Check if expired
      if (entry.isExpired) {
        _memoryCache.remove(key);
        _cacheMetadata.remove(key);
        _cacheMisses++;
        stopwatch.stop();
        
        _performanceService.recordPerformanceMetric(
          PerformanceMetrics(
            operation: 'cache_expired',
            duration: stopwatch.elapsed,
            additionalData: {
              'cache_key': _hashKey(key),
              'expired_at': entry.expiresAt.toIso8601String(),
            },
            timestamp: DateTime.now(),
          ),
        );
        
        return null;
      }
      
      // Update access time for LRU
      entry.lastAccessed = DateTime.now();
      _updateCacheMetadata(key, entry);
      
      _cacheHits++;
      stopwatch.stop();
      
      _performanceService.recordPerformanceMetric(
        PerformanceMetrics(
          operation: 'cache_hit',
          duration: stopwatch.elapsed,
          additionalData: {
            'cache_key': _hashKey(key),
            'data_size': entry.data.length,
            'age_seconds': DateTime.now().difference(entry.createdAt).inSeconds,
          },
          timestamp: DateTime.now(),
        ),
      );
      
      _eventController.add(
        CacheEvent(
          type: CacheEventType.hit,
          key: _hashKey(key),
          size: entry.data.length,
          timestamp: DateTime.now(),
        ),
      );
      
      return CachedResponse(
        data: entry.data,
        headers: entry.headers,
        statusCode: entry.statusCode,
        cachedAt: entry.createdAt,
      );
    } catch (e) {
      stopwatch.stop();
      _logger.warning('Cache get operation failed: $e');
      return null;
    }
  }

  /// Store response in cache
  Future<void> put(
    String key,
    Uint8List data,
    Map<String, String> headers,
    int statusCode, {
    Duration? ttl,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final effectiveTtl = ttl ?? defaultTtl;
      final now = DateTime.now();
      
      final entry = NetworkCacheEntry(
        data: data,
        headers: headers,
        statusCode: statusCode,
        createdAt: now,
        lastAccessed: now,
        expiresAt: now.add(effectiveTtl),
      );
      
      // Check if we need to evict entries first
      await _ensureCacheSpace(data.length);
      
      _memoryCache[key] = entry;
      _updateCacheMetadata(key, entry);
      
      stopwatch.stop();
      
      _performanceService.recordPerformanceMetric(
        PerformanceMetrics(
          operation: 'cache_put',
          duration: stopwatch.elapsed,
          additionalData: {
            'cache_key': _hashKey(key),
            'data_size': data.length,
            'ttl_seconds': effectiveTtl.inSeconds,
            'cache_size_after': _memoryCache.length,
          },
          timestamp: DateTime.now(),
        ),
      );
      
      _eventController.add(
        CacheEvent(
          type: CacheEventType.store,
          key: _hashKey(key),
          size: data.length,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      stopwatch.stop();
      _logger.warning('Cache put operation failed: $e');
    }
  }

  /// Ensure there's enough space in cache
  Future<void> _ensureCacheSpace(int requiredSize) async {
    // Check total cache size
    final currentSize = _calculateTotalCacheSize();
    
    if (currentSize + requiredSize > maxMemoryCacheSize || 
        _memoryCache.length >= maxCacheEntries) {
      await _evictLeastRecentlyUsed(requiredSize);
    }
  }

  /// Evict least recently used entries
  Future<void> _evictLeastRecentlyUsed(int requiredSize) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final entries = _memoryCache.entries.toList();
      entries.sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));
      
      int freedSize = 0;
      int evictedCount = 0;
      
      for (final entry in entries) {
        if (freedSize >= requiredSize && _memoryCache.length < maxCacheEntries) {
          break;
        }
        
        freedSize += entry.value.data.length;
        evictedCount++;
        
        _memoryCache.remove(entry.key);
        _cacheMetadata.remove(entry.key);
        _cacheEvictions++;
        
        _eventController.add(
          CacheEvent(
            type: CacheEventType.evict,
            key: _hashKey(entry.key),
            size: entry.value.data.length,
            timestamp: DateTime.now(),
          ),
        );
      }
      
      stopwatch.stop();
      
      _performanceService.recordPerformanceMetric(
        PerformanceMetrics(
          operation: 'cache_eviction',
          duration: stopwatch.elapsed,
          additionalData: {
            'evicted_count': evictedCount,
            'freed_bytes': freedSize,
            'cache_size_after': _memoryCache.length,
          },
          timestamp: DateTime.now(),
        ),
      );
      
      _logger.info('Evicted $evictedCount cache entries, freed ${_formatBytes(freedSize)}');
    } catch (e) {
      stopwatch.stop();
      _logger.warning('Cache eviction failed: $e');
    }
  }

  /// Perform periodic cache cleanup
  void _performCacheCleanup() {
    final stopwatch = Stopwatch()..start();
    
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];
      
      for (final entry in _memoryCache.entries) {
        if (entry.value.expiresAt.isBefore(now)) {
          expiredKeys.add(entry.key);
        }
      }
      
      for (final key in expiredKeys) {
        final entry = _memoryCache.remove(key);
        _cacheMetadata.remove(key);
        
        if (entry != null) {
          _eventController.add(
            CacheEvent(
              type: CacheEventType.expire,
              key: _hashKey(key),
              size: entry.data.length,
              timestamp: DateTime.now(),
            ),
          );
        }
      }
      
      stopwatch.stop();
      
      if (expiredKeys.isNotEmpty) {
        _performanceService.recordPerformanceMetric(
          PerformanceMetrics(
            operation: 'cache_cleanup',
            duration: stopwatch.elapsed,
            additionalData: {
              'expired_count': expiredKeys.length,
              'cache_size_after': _memoryCache.length,
            },
            timestamp: DateTime.now(),
          ),
        );
        
        _logger.info('Cleaned up ${expiredKeys.length} expired cache entries');
      }
    } catch (e) {
      stopwatch.stop();
      _logger.warning('Cache cleanup failed: $e');
    }
  }

  /// Report cache statistics
  void _reportCacheStatistics() {
    final hitRate = _totalRequests > 0 ? (_cacheHits / _totalRequests) * 100 : 0.0;
    final totalSize = _calculateTotalCacheSize();
    
    _performanceService.recordPerformanceMetric(
      PerformanceMetrics(
        operation: 'cache_statistics',
        duration: Duration.zero,
        additionalData: {
          'cache_hits': _cacheHits,
          'cache_misses': _cacheMisses,
          'cache_evictions': _cacheEvictions,
          'total_requests': _totalRequests,
          'hit_rate_percent': hitRate,
          'cache_entries': _memoryCache.length,
          'total_size_bytes': totalSize,
          'max_size_bytes': maxMemoryCacheSize,
          'utilization_percent': (totalSize / maxMemoryCacheSize) * 100,
        },
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Update cache metadata
  void _updateCacheMetadata(String key, NetworkCacheEntry entry) {
    _cacheMetadata[key] = CacheMetadata(
      key: key,
      size: entry.data.length,
      createdAt: entry.createdAt,
      lastAccessed: entry.lastAccessed,
      expiresAt: entry.expiresAt,
      accessCount: (_cacheMetadata[key]?.accessCount ?? 0) + 1,
    );
  }

  /// Calculate total cache size
  int _calculateTotalCacheSize() {
    return _memoryCache.values.fold(0, (sum, entry) => sum + entry.data.length);
  }

  /// Hash cache key for logging (privacy)
  String _hashKey(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8);
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    final hitRate = _totalRequests > 0 ? (_cacheHits / _totalRequests) * 100 : 0.0;
    final totalSize = _calculateTotalCacheSize();
    
    return {
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'cache_evictions': _cacheEvictions,
      'total_requests': _totalRequests,
      'hit_rate_percent': hitRate,
      'cache_entries': _memoryCache.length,
      'max_entries': maxCacheEntries,
      'total_size_bytes': totalSize,
      'total_size_formatted': _formatBytes(totalSize),
      'max_size_bytes': maxMemoryCacheSize,
      'max_size_formatted': _formatBytes(maxMemoryCacheSize),
      'utilization_percent': (totalSize / maxMemoryCacheSize) * 100,
      'average_entry_size': _memoryCache.isNotEmpty 
          ? totalSize / _memoryCache.length 
          : 0,
    };
  }

  /// Get cache events stream
  Stream<CacheEvent> get events => _eventController.stream;

  /// Clear all cache entries
  Future<void> clearCache() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final entriesCleared = _memoryCache.length;
      final sizeCleared = _calculateTotalCacheSize();
      
      _memoryCache.clear();
      _cacheMetadata.clear();
      
      stopwatch.stop();
      
      _performanceService.recordPerformanceMetric(
        PerformanceMetrics(
          operation: 'cache_clear',
          duration: stopwatch.elapsed,
          additionalData: {
            'entries_cleared': entriesCleared,
            'size_cleared': sizeCleared,
          },
          timestamp: DateTime.now(),
        ),
      );
      
      _logger.info('Cleared $entriesCleared cache entries, freed ${_formatBytes(sizeCleared)}');
    } catch (e) {
      stopwatch.stop();
      _logger.warning('Cache clear failed: $e');
    }
  }

  /// Optimize cache performance
  Future<void> optimizeCache() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Remove expired entries
      _performCacheCleanup();
      
      // If hit rate is low, consider clearing cache
      final hitRate = _totalRequests > 0 ? (_cacheHits / _totalRequests) * 100 : 0.0;
      if (hitRate < 20.0 && _totalRequests > 100) {
        await clearCache();
        _logger.info('Cache cleared due to low hit rate: ${hitRate.toStringAsFixed(1)}%');
      }
      
      stopwatch.stop();
      
      _performanceService.recordPerformanceMetric(
        PerformanceMetrics(
          operation: 'cache_optimization',
          duration: stopwatch.elapsed,
          additionalData: {
            'hit_rate_percent': hitRate,
            'total_requests': _totalRequests,
          },
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      stopwatch.stop();
      _logger.warning('Cache optimization failed: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _statsTimer?.cancel();
    _eventController.close();
    _memoryCache.clear();
    _cacheMetadata.clear();
  }
}

/// Network cache entry
class NetworkCacheEntry {
  final Uint8List data;
  final Map<String, String> headers;
  final int statusCode;
  final DateTime createdAt;
  DateTime lastAccessed;
  final DateTime expiresAt;

  NetworkCacheEntry({
    required this.data,
    required this.headers,
    required this.statusCode,
    required this.createdAt,
    required this.lastAccessed,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Cache metadata for analytics
class CacheMetadata {
  final String key;
  final int size;
  final DateTime createdAt;
  final DateTime lastAccessed;
  final DateTime expiresAt;
  final int accessCount;

  CacheMetadata({
    required this.key,
    required this.size,
    required this.createdAt,
    required this.lastAccessed,
    required this.expiresAt,
    required this.accessCount,
  });
}

/// Cached response
class CachedResponse {
  final Uint8List data;
  final Map<String, String> headers;
  final int statusCode;
  final DateTime cachedAt;

  CachedResponse({
    required this.data,
    required this.headers,
    required this.statusCode,
    required this.cachedAt,
  });
}

/// Cache event
class CacheEvent {
  final CacheEventType type;
  final String key;
  final int size;
  final DateTime timestamp;

  CacheEvent({
    required this.type,
    required this.key,
    required this.size,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'key': key,
    'size': size,
    'timestamp': timestamp.toIso8601String(),
  };
}

enum CacheEventType {
  hit,
  miss,
  store,
  evict,
  expire,
}