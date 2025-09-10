import 'dart:async';
import 'performance_monitoring_service.dart';

/// Generic performance metrics data structure
class GenericMetrics {
  final String operationName;
  final Duration duration;
  final Map<String, dynamic>? additionalData;
  final DateTime timestamp;
  final bool isSlowOperation;

  GenericMetrics({
    required this.operationName,
    required this.duration,
    this.additionalData,
    required this.timestamp,
    this.isSlowOperation = false,
  });

  Map<String, dynamic> toJson() => {
    'operation_name': operationName,
    'duration_ms': duration.inMilliseconds,
    'additional_data': additionalData,
    'timestamp': timestamp.toIso8601String(),
    'is_slow_operation': isSlowOperation,
  };
}

/// Enhanced mixin for adding performance monitoring to services
mixin PerformanceMonitoringMixin {
  PerformanceMonitoringService? _performanceService;
  
  /// Set the performance monitoring service
  void setPerformanceMonitoringService(PerformanceMonitoringService service) {
    _performanceService = service;
  }

  /// Measure and record the performance of an async operation
  Future<T> measurePerformance<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? additionalData,
    Duration? slowThreshold,
  }) async {
    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      _recordMetric(
        operationName,
        stopwatch.elapsed,
        additionalData,
        startTime,
        slowThreshold,
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      _recordMetric(
        '$operationName (failed)',
        stopwatch.elapsed,
        {
          ...?additionalData,
          'error': e.toString(),
          'error_type': e.runtimeType.toString(),
        },
        startTime,
        slowThreshold,
      );
      
      rethrow;
    }
  }

  /// Measure and record synchronous operations
  T measureSyncPerformance<T>(
    String operationName,
    T Function() operation, {
    Map<String, dynamic>? additionalData,
    Duration? slowThreshold,
  }) {
    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();
    
    try {
      final result = operation();
      stopwatch.stop();
      
      _recordMetric(
        operationName,
        stopwatch.elapsed,
        additionalData,
        startTime,
        slowThreshold,
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      _recordMetric(
        '$operationName (failed)',
        stopwatch.elapsed,
        {
          ...?additionalData,
          'error': e.toString(),
          'error_type': e.runtimeType.toString(),
        },
        startTime,
        slowThreshold,
      );
      
      rethrow;
    }
  }

  /// Measure network request performance
  Future<T> measureNetworkRequest<T>(
    String endpoint,
    String method,
    Future<T> Function() request, {
    Map<String, dynamic>? additionalData,
  }) async {
    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();
    
    try {
      final result = await request();
      stopwatch.stop();
      
      // Try to determine response size and status code
      int? responseSize;
      int statusCode = 200; // Assume success
      bool fromCache = false;
      
      if (additionalData != null) {
        responseSize = additionalData['response_size'] as int?;
        statusCode = additionalData['status_code'] as int? ?? 200;
        fromCache = additionalData['from_cache'] as bool? ?? false;
      }
      
      _performanceService?.recordNetworkMetric(
        NetworkMetrics(
          endpoint: endpoint,
          method: method,
          duration: stopwatch.elapsed,
          responseSize: responseSize,
          statusCode: statusCode,
          fromCache: fromCache,
          timestamp: startTime,
        ),
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      int statusCode = 0;
      if (additionalData != null) {
        statusCode = additionalData['status_code'] as int? ?? 0;
      }
      
      _performanceService?.recordNetworkMetric(
        NetworkMetrics(
          endpoint: endpoint,
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

  /// Measure database operation performance
  Future<T> measureDatabaseOperation<T>(
    String query,
    String operation,
    Future<T> Function() databaseCall, {
    Map<String, dynamic>? additionalData,
  }) async {
    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();
    
    try {
      final result = await databaseCall();
      stopwatch.stop();
      
      int? resultCount;
      if (result is List) {
        resultCount = result.length;
      } else if (result is int) {
        resultCount = result;
      } else if (additionalData != null) {
        resultCount = additionalData['result_count'] as int?;
      }
      
      _performanceService?.recordDatabaseMetric(
        DatabaseMetrics(
          query: _sanitizeQuery(query),
          duration: stopwatch.elapsed,
          resultCount: resultCount,
          operation: operation,
          timestamp: startTime,
        ),
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      _performanceService?.recordDatabaseMetric(
        DatabaseMetrics(
          query: '${_sanitizeQuery(query)} - FAILED',
          duration: stopwatch.elapsed,
          resultCount: null,
          operation: operation,
          timestamp: startTime,
        ),
      );
      
      rethrow;
    }
  }

  /// Measure rendering operation performance
  Future<T> measureRenderingOperation<T>(
    String documentId,
    int pageNumber,
    String renderingMethod,
    Future<T> Function() renderingCall, {
    Map<String, dynamic>? additionalData,
  }) async {
    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();
    
    try {
      final result = await renderingCall();
      stopwatch.stop();
      
      int? imageSizeBytes;
      if (additionalData != null) {
        imageSizeBytes = additionalData['image_size_bytes'] as int?;
      }
      
      _performanceService?.recordRenderingMetric(
        RenderingMetrics(
          documentId: documentId,
          pageNumber: pageNumber,
          duration: stopwatch.elapsed,
          renderingMethod: renderingMethod,
          imageSizeBytes: imageSizeBytes,
          timestamp: startTime,
        ),
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      _performanceService?.recordRenderingMetric(
        RenderingMetrics(
          documentId: documentId,
          pageNumber: pageNumber,
          duration: stopwatch.elapsed,
          renderingMethod: '$renderingMethod (failed)',
          imageSizeBytes: null,
          timestamp: startTime,
        ),
      );
      
      rethrow;
    }
  }

  /// Record a generic performance metric
  void _recordMetric(
    String operationName,
    Duration duration,
    Map<String, dynamic>? additionalData,
    DateTime startTime,
    Duration? slowThreshold,
  ) {
    if (_performanceService == null) return;

    final isSlowOperation = slowThreshold != null && duration > slowThreshold;
    
    _performanceService!.recordGenericMetric(
      GenericMetrics(
        operationName: operationName,
        duration: duration,
        additionalData: additionalData,
        timestamp: startTime,
        isSlowOperation: isSlowOperation,
      ),
    );
  }

  /// Sanitize SQL query for logging (remove sensitive data)
  String _sanitizeQuery(String query) {
    // Remove potential sensitive data from queries
    return query
        .replaceAll(RegExp(r"'[^']*'"), "'***'")  // Replace string literals
        .replaceAll(RegExp(r'\b\d+\b'), '***')    // Replace numbers
        .trim();
  }
}