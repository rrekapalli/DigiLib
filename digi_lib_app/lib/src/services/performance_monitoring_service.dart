import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logging/logging.dart';

/// Performance metrics data structure
class PerformanceMetrics {
  final String operation;
  final Duration duration;
  final int? memoryUsage;
  final Map<String, dynamic>? additionalData;
  final DateTime timestamp;

  PerformanceMetrics({
    required this.operation,
    required this.duration,
    this.memoryUsage,
    this.additionalData,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'operation': operation,
    'duration_ms': duration.inMilliseconds,
    'memory_usage_bytes': memoryUsage,
    'additional_data': additionalData,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Memory usage information
class MemoryInfo {
  final int rssBytes;
  final int heapUsageBytes;
  final int externalBytes;

  MemoryInfo({
    required this.rssBytes,
    required this.heapUsageBytes,
    required this.externalBytes,
  });

  Map<String, dynamic> toJson() => {
    'rss_bytes': rssBytes,
    'heap_usage_bytes': heapUsageBytes,
    'external_bytes': externalBytes,
  };
}

/// Network request performance data
class NetworkMetrics {
  final String endpoint;
  final String method;
  final Duration duration;
  final int? responseSize;
  final int statusCode;
  final bool fromCache;
  final DateTime timestamp;

  NetworkMetrics({
    required this.endpoint,
    required this.method,
    required this.duration,
    this.responseSize,
    required this.statusCode,
    required this.fromCache,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'endpoint': endpoint,
    'method': method,
    'duration_ms': duration.inMilliseconds,
    'response_size_bytes': responseSize,
    'status_code': statusCode,
    'from_cache': fromCache,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Database query performance data
class DatabaseMetrics {
  final String query;
  final Duration duration;
  final int? resultCount;
  final String operation; // SELECT, INSERT, UPDATE, DELETE
  final DateTime timestamp;

  DatabaseMetrics({
    required this.query,
    required this.duration,
    this.resultCount,
    required this.operation,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'query': query,
    'duration_ms': duration.inMilliseconds,
    'result_count': resultCount,
    'operation': operation,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Rendering performance data
class RenderingMetrics {
  final String documentId;
  final int pageNumber;
  final Duration duration;
  final String renderingMethod; // native, server, cached
  final int? imageSizeBytes;
  final DateTime timestamp;

  RenderingMetrics({
    required this.documentId,
    required this.pageNumber,
    required this.duration,
    required this.renderingMethod,
    this.imageSizeBytes,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'document_id': documentId,
    'page_number': pageNumber,
    'duration_ms': duration.inMilliseconds,
    'rendering_method': renderingMethod,
    'image_size_bytes': imageSizeBytes,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Performance monitoring service
class PerformanceMonitoringService {
  static final Logger _logger = Logger('PerformanceMonitoringService');
  
  final List<PerformanceMetrics> _performanceMetrics = [];
  final List<NetworkMetrics> _networkMetrics = [];
  final List<DatabaseMetrics> _databaseMetrics = [];
  final List<RenderingMetrics> _renderingMetrics = [];
  
  Timer? _memoryMonitoringTimer;
  final StreamController<MemoryInfo> _memoryStreamController = StreamController<MemoryInfo>.broadcast();
  
  // Configuration
  static const int maxMetricsCount = 1000;
  static const Duration memoryMonitoringInterval = Duration(seconds: 30);
  
  /// Initialize performance monitoring
  Future<void> initialize() async {
    _logger.info('Initializing performance monitoring service');
    
    // Start memory monitoring
    _startMemoryMonitoring();
    
    // Log device information
    await _logDeviceInfo();
  }

  /// Start monitoring memory usage
  void _startMemoryMonitoring() {
    _memoryMonitoringTimer = Timer.periodic(memoryMonitoringInterval, (timer) {
      _collectMemoryInfo();
    });
  }

  /// Collect current memory information
  void _collectMemoryInfo() {
    try {
      final info = ProcessInfo.currentRss;
      final memoryInfo = MemoryInfo(
        rssBytes: info,
        heapUsageBytes: ProcessInfo.currentRss, // Approximation
        externalBytes: 0, // Not directly available in Dart
      );
      
      _memoryStreamController.add(memoryInfo);
      _logger.fine('Memory usage: ${memoryInfo.toJson()}');
    } catch (e) {
      _logger.warning('Failed to collect memory info: $e');
    }
  }

  /// Log device information for context
  Future<void> _logDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _logger.info('Device: ${androidInfo.model}, Android ${androidInfo.version.release}');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _logger.info('Device: ${iosInfo.model}, iOS ${iosInfo.systemVersion}');
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        _logger.info('Device: Windows ${windowsInfo.displayVersion}');
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        _logger.info('Device: macOS ${macInfo.osRelease}');
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        _logger.info('Device: ${linuxInfo.prettyName}');
      }
    } catch (e) {
      _logger.warning('Failed to get device info: $e');
    }
  }

  /// Record a performance metric
  void recordPerformanceMetric(PerformanceMetrics metric) {
    _performanceMetrics.add(metric);
    _trimMetrics(_performanceMetrics);
    
    _logger.fine('Performance metric: ${metric.toJson()}');
    
    // Log slow operations
    if (metric.duration.inMilliseconds > 1000) {
      _logger.warning('Slow operation detected: ${metric.operation} took ${metric.duration.inMilliseconds}ms');
    }
  }

  /// Record a network metric
  void recordNetworkMetric(NetworkMetrics metric) {
    _networkMetrics.add(metric);
    _trimMetrics(_networkMetrics);
    
    _logger.fine('Network metric: ${metric.toJson()}');
    
    // Log slow network requests
    if (metric.duration.inMilliseconds > 5000) {
      _logger.warning('Slow network request: ${metric.method} ${metric.endpoint} took ${metric.duration.inMilliseconds}ms');
    }
  }

  /// Record a database metric
  void recordDatabaseMetric(DatabaseMetrics metric) {
    _databaseMetrics.add(metric);
    _trimMetrics(_databaseMetrics);
    
    _logger.fine('Database metric: ${metric.toJson()}');
    
    // Log slow queries
    if (metric.duration.inMilliseconds > 500) {
      _logger.warning('Slow database query: ${metric.operation} took ${metric.duration.inMilliseconds}ms');
    }
  }

  /// Record a rendering metric
  void recordRenderingMetric(RenderingMetrics metric) {
    _renderingMetrics.add(metric);
    _trimMetrics(_renderingMetrics);
    
    _logger.fine('Rendering metric: ${metric.toJson()}');
    
    // Log slow rendering
    if (metric.duration.inMilliseconds > 2000) {
      _logger.warning('Slow rendering: Page ${metric.pageNumber} took ${metric.duration.inMilliseconds}ms');
    }
  }

  /// Record a generic metric (for compatibility with mixin)
  void recordGenericMetric(dynamic metric) {
    // Convert generic metric to performance metric
    if (metric is Map<String, dynamic>) {
      final performanceMetric = PerformanceMetrics(
        operation: metric['operation_name'] ?? 'unknown',
        duration: Duration(milliseconds: metric['duration_ms'] ?? 0),
        additionalData: metric['additional_data'],
        timestamp: DateTime.tryParse(metric['timestamp'] ?? '') ?? DateTime.now(),
      );
      recordPerformanceMetric(performanceMetric);
    } else {
      // Assume it has the required properties
      try {
        final performanceMetric = PerformanceMetrics(
          operation: metric.operationName ?? 'unknown',
          duration: metric.duration ?? Duration.zero,
          additionalData: metric.additionalData,
          timestamp: metric.timestamp ?? DateTime.now(),
        );
        recordPerformanceMetric(performanceMetric);
      } catch (e) {
        _logger.warning('Failed to record generic metric: $e');
      }
    }
  }

  /// Trim metrics list to prevent memory leaks
  void _trimMetrics<T>(List<T> metrics) {
    if (metrics.length > maxMetricsCount) {
      metrics.removeRange(0, metrics.length - maxMetricsCount);
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'performance_metrics_count': _performanceMetrics.length,
      'network_metrics_count': _networkMetrics.length,
      'database_metrics_count': _databaseMetrics.length,
      'rendering_metrics_count': _renderingMetrics.length,
      'avg_network_duration_ms': _calculateAverageNetworkDuration(),
      'avg_database_duration_ms': _calculateAverageDatabaseDuration(),
      'avg_rendering_duration_ms': _calculateAverageRenderingDuration(),
      'slow_operations_count': _countSlowOperations(),
    };
  }

  /// Calculate average network request duration
  double _calculateAverageNetworkDuration() {
    if (_networkMetrics.isEmpty) return 0.0;
    
    final totalMs = _networkMetrics
        .map((m) => m.duration.inMilliseconds)
        .reduce((a, b) => a + b);
    
    return totalMs / _networkMetrics.length;
  }

  /// Calculate average database query duration
  double _calculateAverageDatabaseDuration() {
    if (_databaseMetrics.isEmpty) return 0.0;
    
    final totalMs = _databaseMetrics
        .map((m) => m.duration.inMilliseconds)
        .reduce((a, b) => a + b);
    
    return totalMs / _databaseMetrics.length;
  }

  /// Calculate average rendering duration
  double _calculateAverageRenderingDuration() {
    if (_renderingMetrics.isEmpty) return 0.0;
    
    final totalMs = _renderingMetrics
        .map((m) => m.duration.inMilliseconds)
        .reduce((a, b) => a + b);
    
    return totalMs / _renderingMetrics.length;
  }

  /// Count slow operations across all metrics
  int _countSlowOperations() {
    int count = 0;
    
    count += _performanceMetrics.where((m) => m.duration.inMilliseconds > 1000).length;
    count += _networkMetrics.where((m) => m.duration.inMilliseconds > 5000).length;
    count += _databaseMetrics.where((m) => m.duration.inMilliseconds > 500).length;
    count += _renderingMetrics.where((m) => m.duration.inMilliseconds > 2000).length;
    
    return count;
  }

  /// Get memory usage stream
  Stream<MemoryInfo> get memoryUsageStream => _memoryStreamController.stream;

  /// Get recent performance metrics
  List<PerformanceMetrics> getRecentPerformanceMetrics({int limit = 100}) {
    final startIndex = _performanceMetrics.length > limit ? _performanceMetrics.length - limit : 0;
    return _performanceMetrics.sublist(startIndex);
  }

  /// Get recent network metrics
  List<NetworkMetrics> getRecentNetworkMetrics({int limit = 100}) {
    final startIndex = _networkMetrics.length > limit ? _networkMetrics.length - limit : 0;
    return _networkMetrics.sublist(startIndex);
  }

  /// Get recent database metrics
  List<DatabaseMetrics> getRecentDatabaseMetrics({int limit = 100}) {
    final startIndex = _databaseMetrics.length > limit ? _databaseMetrics.length - limit : 0;
    return _databaseMetrics.sublist(startIndex);
  }

  /// Get recent rendering metrics
  List<RenderingMetrics> getRecentRenderingMetrics({int limit = 100}) {
    final startIndex = _renderingMetrics.length > limit ? _renderingMetrics.length - limit : 0;
    return _renderingMetrics.sublist(startIndex);
  }

  /// Clear all metrics
  void clearMetrics() {
    _performanceMetrics.clear();
    _networkMetrics.clear();
    _databaseMetrics.clear();
    _renderingMetrics.clear();
    _logger.info('All performance metrics cleared');
  }

  /// Dispose resources
  void dispose() {
    _memoryMonitoringTimer?.cancel();
    _memoryStreamController.close();
    _logger.info('Performance monitoring service disposed');
  }
}

/// Mixin for adding performance monitoring to services
mixin PerformanceMonitoringMixin {
  PerformanceMonitoringService? _performanceService;
  
  void setPerformanceMonitoringService(PerformanceMonitoringService service) {
    _performanceService = service;
  }

  /// Measure and record the performance of an operation
  Future<T> measurePerformance<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? additionalData,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      _performanceService?.recordPerformanceMetric(
        PerformanceMetrics(
          operation: operationName,
          duration: stopwatch.elapsed,
          additionalData: additionalData,
          timestamp: DateTime.now(),
        ),
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      _performanceService?.recordPerformanceMetric(
        PerformanceMetrics(
          operation: '$operationName (failed)',
          duration: stopwatch.elapsed,
          additionalData: {
            ...?additionalData,
            'error': e.toString(),
          },
          timestamp: DateTime.now(),
        ),
      );
      
      rethrow;
    }
  }

  /// Measure and record synchronous operations
  T measureSyncPerformance<T>(
    String operationName,
    T Function() operation, {
    Map<String, dynamic>? additionalData,
  }) {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = operation();
      stopwatch.stop();
      
      _performanceService?.recordPerformanceMetric(
        PerformanceMetrics(
          operation: operationName,
          duration: stopwatch.elapsed,
          additionalData: additionalData,
          timestamp: DateTime.now(),
        ),
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      _performanceService?.recordPerformanceMetric(
        PerformanceMetrics(
          operation: '$operationName (failed)',
          duration: stopwatch.elapsed,
          additionalData: {
            ...?additionalData,
            'error': e.toString(),
          },
          timestamp: DateTime.now(),
        ),
      );
      
      rethrow;
    }
  }
}