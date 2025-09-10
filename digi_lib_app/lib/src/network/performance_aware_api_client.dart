import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../services/performance_monitoring_service.dart';

/// Performance-aware API client that wraps the base API client
class PerformanceAwareApiClient implements ApiClient {
  final ApiClient _baseClient;
  final PerformanceMonitoringService _performanceService;

  PerformanceAwareApiClient(this._baseClient, this._performanceService);

  @override
  String get baseUrl => _baseClient.baseUrl;

  @override
  bool get hasAuthToken => _baseClient.hasAuthToken;

  @override
  void setAuthToken(String token) {
    _baseClient.setAuthToken(token);
  }

  @override
  void clearAuthToken() {
    _baseClient.clearAuthToken();
  }

  @override
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParams}) async {
    return _measureNetworkRequest(
      'GET',
      path,
      () => _baseClient.get<T>(path, queryParams: queryParams),
      queryParams: queryParams,
    );
  }

  @override
  Future<T> post<T>(String path, {Object? body, Map<String, dynamic>? queryParams}) async {
    return _measureNetworkRequest(
      'POST',
      path,
      () => _baseClient.post<T>(path, body: body, queryParams: queryParams),
      body: body,
      queryParams: queryParams,
    );
  }

  @override
  Future<T> put<T>(String path, {Object? body}) async {
    return _measureNetworkRequest(
      'PUT',
      path,
      () => _baseClient.put<T>(path, body: body),
      body: body,
    );
  }

  @override
  Future<T> delete<T>(String path) async {
    return _measureNetworkRequest(
      'DELETE',
      path,
      () => _baseClient.delete<T>(path),
    );
  }

  /// Measure network request performance
  Future<T> _measureNetworkRequest<T>(
    String method,
    String path,
    Future<T> Function() request, {
    Object? body,
    Map<String, dynamic>? queryParams,
  }) async {
    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();
    
    try {
      final result = await request();
      stopwatch.stop();
      
      // Calculate response size
      int? responseSize;
      try {
        if (result != null) {
          final jsonString = jsonEncode(result);
          responseSize = utf8.encode(jsonString).length;
        }
      } catch (e) {
        // Ignore encoding errors for size calculation
      }
      
      // Record successful network metric
      _performanceService.recordNetworkMetric(
        NetworkMetrics(
          endpoint: path,
          method: method,
          duration: stopwatch.elapsed,
          responseSize: responseSize,
          statusCode: 200, // Assume success if no exception
          fromCache: false, // TODO: Implement cache detection
          timestamp: startTime,
        ),
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      // Determine status code from exception
      int statusCode = 0;
      if (e is DioException && e.response != null) {
        statusCode = e.response!.statusCode ?? 0;
      }
      
      // Record failed network metric
      _performanceService.recordNetworkMetric(
        NetworkMetrics(
          endpoint: path,
          method: method,
          duration: stopwatch.elapsed,
          responseSize: null,
          statusCode: statusCode,
          fromCache: false,
          timestamp: startTime,
        ),
      );
      
      rethrow;
    }
  }
}

/// Interceptor for Dio to add performance monitoring
class PerformanceMonitoringInterceptor extends Interceptor {
  final PerformanceMonitoringService _performanceService;

  PerformanceMonitoringInterceptor(this._performanceService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['start_time'] = DateTime.now();
    options.extra['stopwatch'] = Stopwatch()..start();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _recordNetworkMetric(response.requestOptions, response.statusCode ?? 200, response.data);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _recordNetworkMetric(
      err.requestOptions, 
      err.response?.statusCode ?? 0, 
      null,
    );
    handler.next(err);
  }

  void _recordNetworkMetric(RequestOptions options, int statusCode, dynamic responseData) {
    final stopwatch = options.extra['stopwatch'] as Stopwatch?;
    final startTime = options.extra['start_time'] as DateTime?;
    
    if (stopwatch != null && startTime != null) {
      stopwatch.stop();
      
      // Calculate response size
      int? responseSize;
      try {
        if (responseData != null) {
          final jsonString = jsonEncode(responseData);
          responseSize = utf8.encode(jsonString).length;
        }
      } catch (e) {
        // Ignore encoding errors
      }
      
      _performanceService.recordNetworkMetric(
        NetworkMetrics(
          endpoint: options.path,
          method: options.method,
          duration: stopwatch.elapsed,
          responseSize: responseSize,
          statusCode: statusCode,
          fromCache: false, // TODO: Implement cache detection
          timestamp: startTime,
        ),
      );
    }
  }
}

/// Cache-aware API client wrapper
class CacheAwareApiClient implements ApiClient {
  final ApiClient _baseClient;
  final PerformanceMonitoringService _performanceService;
  final Map<String, _CacheEntry> _cache = {};
  
  // Cache configuration
  static const Duration defaultCacheDuration = Duration(minutes: 5);
  static const int maxCacheSize = 100;

  CacheAwareApiClient(this._baseClient, this._performanceService);

  @override
  String get baseUrl => _baseClient.baseUrl;

  @override
  bool get hasAuthToken => _baseClient.hasAuthToken;

  @override
  void setAuthToken(String token) {
    _baseClient.setAuthToken(token);
    // Clear cache when auth token changes
    _cache.clear();
  }

  @override
  void clearAuthToken() {
    _baseClient.clearAuthToken();
    _cache.clear();
  }

  @override
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParams}) async {
    final cacheKey = _generateCacheKey('GET', path, queryParams);
    
    // Check cache first
    final cachedEntry = _cache[cacheKey];
    if (cachedEntry != null && !cachedEntry.isExpired) {
      // Record cache hit
      _performanceService.recordNetworkMetric(
        NetworkMetrics(
          endpoint: path,
          method: 'GET',
          duration: Duration.zero,
          responseSize: cachedEntry.sizeBytes,
          statusCode: 200,
          fromCache: true,
          timestamp: DateTime.now(),
        ),
      );
      
      return cachedEntry.data as T;
    }
    
    // Cache miss - fetch from network
    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();
    
    try {
      final result = await _baseClient.get<T>(path, queryParams: queryParams);
      stopwatch.stop();
      
      // Cache the result
      _cacheResult(cacheKey, result);
      
      // Calculate response size
      int? responseSize;
      try {
        if (result != null) {
          final jsonString = jsonEncode(result);
          responseSize = utf8.encode(jsonString).length;
        }
      } catch (e) {
        // Ignore encoding errors
      }
      
      _performanceService.recordNetworkMetric(
        NetworkMetrics(
          endpoint: path,
          method: 'GET',
          duration: stopwatch.elapsed,
          responseSize: responseSize,
          statusCode: 200,
          fromCache: false,
          timestamp: startTime,
        ),
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      // Record failed request
      int statusCode = 0;
      if (e is DioException && e.response != null) {
        statusCode = e.response!.statusCode ?? 0;
      }
      
      _performanceService.recordNetworkMetric(
        NetworkMetrics(
          endpoint: path,
          method: 'GET',
          duration: stopwatch.elapsed,
          responseSize: null,
          statusCode: statusCode,
          fromCache: false,
          timestamp: startTime,
        ),
      );
      
      rethrow;
    }
  }

  @override
  Future<T> post<T>(String path, {Object? body, Map<String, dynamic>? queryParams}) async {
    // POST requests are not cached
    return _baseClient.post<T>(path, body: body, queryParams: queryParams);
  }

  @override
  Future<T> put<T>(String path, {Object? body}) async {
    // PUT requests are not cached and invalidate related cache entries
    _invalidateCache(path);
    return _baseClient.put<T>(path, body: body);
  }

  @override
  Future<T> delete<T>(String path) async {
    // DELETE requests are not cached and invalidate related cache entries
    _invalidateCache(path);
    return _baseClient.delete<T>(path);
  }

  String _generateCacheKey(String method, String path, Map<String, dynamic>? queryParams) {
    final buffer = StringBuffer()..write(method)..write(':')..write(path);
    
    if (queryParams != null && queryParams.isNotEmpty) {
      final sortedKeys = queryParams.keys.toList()..sort();
      buffer.write('?');
      for (int i = 0; i < sortedKeys.length; i++) {
        if (i > 0) buffer.write('&');
        buffer.write(sortedKeys[i]);
        buffer.write('=');
        buffer.write(queryParams[sortedKeys[i]]);
      }
    }
    
    return buffer.toString();
  }

  void _cacheResult(String key, dynamic data) {
    // Calculate size
    int sizeBytes = 0;
    try {
      final jsonString = jsonEncode(data);
      sizeBytes = utf8.encode(jsonString).length;
    } catch (e) {
      // Ignore encoding errors
    }
    
    _cache[key] = _CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      sizeBytes: sizeBytes,
    );
    
    // Trim cache if it gets too large
    _trimCache();
  }

  void _invalidateCache(String path) {
    _cache.removeWhere((key, entry) => key.contains(path));
  }

  void _trimCache() {
    if (_cache.length > maxCacheSize) {
      // Remove oldest entries
      final entries = _cache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      final toRemove = entries.take(_cache.length - maxCacheSize);
      for (final entry in toRemove) {
        _cache.remove(entry.key);
      }
    }
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final totalSize = _cache.values.fold<int>(0, (sum, entry) => sum + entry.sizeBytes);
    
    return {
      'entries': _cache.length,
      'total_size_bytes': totalSize,
      'max_size': maxCacheSize,
    };
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final int sizeBytes;

  _CacheEntry({
    required this.data,
    required this.timestamp,
    required this.sizeBytes,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > CacheAwareApiClient.defaultCacheDuration;
}