import 'dart:typed_data';
import 'dart:async';
import 'performance_monitoring_service.dart';
import 'page_rendering_service.dart' as prs;
import '../models/api/render_response.dart';

/// Performance-aware rendering service that monitors rendering performance
class PerformanceAwareRenderingService {
  final prs.PageRenderingService _baseRenderingService;
  final PerformanceMonitoringService _performanceService;

  PerformanceAwareRenderingService(
    this._baseRenderingService,
    this._performanceService,
  );

  /// Render a page with performance monitoring
  Future<prs.PageRenderResult> renderPage(
    String documentId,
    int pageNumber, {
    int dpi = 150,
    String format = 'webp',
  }) async {
    return _measureRenderingOperation(
      documentId,
      pageNumber,
      'render_page',
      () => _baseRenderingService.renderPage(
        documentId,
        pageNumber,
        dpi: dpi,
        format: format,
      ),
    );
  }

  /// Get page render URL with performance monitoring
  Future<RenderResponse> getPageRenderUrl(
    String documentId,
    int pageNumber, {
    int dpi = 150,
    String format = 'webp',
  }) async {
    return _measureRenderingOperation(
      documentId,
      pageNumber,
      'get_render_url',
      () => _baseRenderingService.getPageRenderUrl(
        documentId,
        pageNumber,
        dpi: dpi,
        format: format,
      ),
    );
  }

  /// Check if page is cached with performance monitoring
  Future<bool> isPageCached(
    String documentId,
    int pageNumber, {
    String format = 'webp',
  }) async {
    return _measureRenderingOperation(
      documentId,
      pageNumber,
      'check_cache',
      () => _baseRenderingService.isPageCached(
        documentId,
        pageNumber,
        format: format,
      ),
    );
  }

  /// Preload pages with performance monitoring
  Future<void> preloadPages(
    String documentId,
    List<int> pageNumbers, {
    int dpi = 150,
  }) async {
    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();
    
    try {
      await _baseRenderingService.preloadPages(
        documentId,
        pageNumbers,
        dpi: dpi,
      );
      
      stopwatch.stop();
      
      _performanceService.recordRenderingMetric(
        RenderingMetrics(
          documentId: documentId,
          pageNumber: pageNumbers.isNotEmpty ? pageNumbers.first : 0,
          duration: stopwatch.elapsed,
          renderingMethod: 'preload_batch',
          imageSizeBytes: null,
          timestamp: startTime,
        ),
      );
      
      // Record performance metric for the batch operation
      _performanceService.recordPerformanceMetric(
        PerformanceMetrics(
          operation: 'preload_pages',
          duration: stopwatch.elapsed,
          additionalData: {
            'document_id': documentId,
            'page_count': pageNumbers.length,
            'pages': pageNumbers,
          },
          timestamp: startTime,
        ),
      );
    } catch (e) {
      stopwatch.stop();
      
      _performanceService.recordRenderingMetric(
        RenderingMetrics(
          documentId: documentId,
          pageNumber: pageNumbers.isNotEmpty ? pageNumbers.first : 0,
          duration: stopwatch.elapsed,
          renderingMethod: 'preload_batch_failed',
          imageSizeBytes: null,
          timestamp: startTime,
        ),
      );
      
      rethrow;
    }
  }

  /// Clear document cache with performance monitoring
  Future<void> clearDocumentCache(String documentId) async {
    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();
    
    try {
      await _baseRenderingService.clearDocumentCache(documentId);
      stopwatch.stop();
      
      _performanceService.recordPerformanceMetric(
        PerformanceMetrics(
          operation: 'clear_document_cache',
          duration: stopwatch.elapsed,
          additionalData: {
            'document_id': documentId,
          },
          timestamp: startTime,
        ),
      );
    } catch (e) {
      stopwatch.stop();
      
      _performanceService.recordPerformanceMetric(
        PerformanceMetrics(
          operation: 'clear_document_cache_failed',
          duration: stopwatch.elapsed,
          additionalData: {
            'document_id': documentId,
            'error': e.toString(),
          },
          timestamp: startTime,
        ),
      );
      
      rethrow;
    }
  }

  /// Get rendering statistics with performance monitoring
  Future<prs.RenderingStatistics> getRenderingStatistics() async {
    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();
    
    try {
      final stats = await _baseRenderingService.getRenderingStatistics();
      stopwatch.stop();
      
      _performanceService.recordPerformanceMetric(
        PerformanceMetrics(
          operation: 'get_rendering_statistics',
          duration: stopwatch.elapsed,
          timestamp: startTime,
        ),
      );
      
      return stats;
    } catch (e) {
      stopwatch.stop();
      
      _performanceService.recordPerformanceMetric(
        PerformanceMetrics(
          operation: 'get_rendering_statistics_failed',
          duration: stopwatch.elapsed,
          additionalData: {
            'error': e.toString(),
          },
          timestamp: startTime,
        ),
      );
      
      rethrow;
    }
  }

  /// Measure rendering operation performance
  Future<T> _measureRenderingOperation<T>(
    String documentId,
    int pageNumber,
    String operationType,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      // Determine rendering method and calculate size
      String renderingMethod = operationType;
      int? imageSizeBytes;
      
      if (result is prs.PageRenderResult) {
        renderingMethod = result.fromCache ? 'cache' : (result.fromNative ? 'native' : 'server');
        imageSizeBytes = result.imageData.length;
      } else if (result is Uint8List) {
        imageSizeBytes = result.length;
        renderingMethod = 'native';
      } else if (result is RenderResponse && operationType == 'get_render_url') {
        renderingMethod = 'server';
      } else if (result is bool && operationType == 'check_cache') {
        renderingMethod = 'cache_check';
      }
      
      _performanceService.recordRenderingMetric(
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
      
      _performanceService.recordRenderingMetric(
        RenderingMetrics(
          documentId: documentId,
          pageNumber: pageNumber,
          duration: stopwatch.elapsed,
          renderingMethod: '${operationType}_failed',
          imageSizeBytes: null,
          timestamp: startTime,
        ),
      );
      
      rethrow;
    }
  }

  /// Get rendering performance statistics
  Map<String, dynamic> getRenderingStats() {
    final recentMetrics = _performanceService.getRecentRenderingMetrics(limit: 100);
    
    if (recentMetrics.isEmpty) {
      return {
        'total_renders': 0,
        'avg_duration_ms': 0.0,
        'rendering_methods': <String, int>{},
        'slow_renders': 0,
      };
    }
    
    final totalDuration = recentMetrics
        .map((m) => m.duration.inMilliseconds)
        .reduce((a, b) => a + b);
    
    final avgDuration = totalDuration / recentMetrics.length;
    
    final methodCounts = <String, int>{};
    for (final metric in recentMetrics) {
      methodCounts[metric.renderingMethod] = 
          (methodCounts[metric.renderingMethod] ?? 0) + 1;
    }
    
    final slowRenders = recentMetrics
        .where((m) => m.duration.inMilliseconds > 2000)
        .length;
    
    return {
      'total_renders': recentMetrics.length,
      'avg_duration_ms': avgDuration,
      'rendering_methods': methodCounts,
      'slow_renders': slowRenders,
      'cache_hit_rate': _calculateCacheHitRate(recentMetrics),
    };
  }

  /// Calculate cache hit rate from rendering metrics
  double _calculateCacheHitRate(List<RenderingMetrics> metrics) {
    if (metrics.isEmpty) return 0.0;
    
    final cacheHits = metrics
        .where((m) => m.renderingMethod.contains('cache') || 
                     m.duration.inMilliseconds < 100)
        .length;
    
    return (cacheHits / metrics.length) * 100;
  }

  /// Optimize rendering performance based on collected metrics
  Future<void> optimizePerformance() async {
    final stats = getRenderingStats();
    final slowRenders = stats['slow_renders'] as int;
    
    if (slowRenders > 10) {
      // Get rendering statistics to identify problematic documents
      final renderingStats = await getRenderingStatistics();
      
      _performanceService.recordPerformanceMetric(
        PerformanceMetrics(
          operation: 'auto_optimize_rendering',
          duration: Duration.zero,
          additionalData: {
            'reason': 'too_many_slow_renders',
            'slow_renders': slowRenders,
          },
          timestamp: DateTime.now(),
        ),
      );
    }
    
    final cacheHitRate = stats['cache_hit_rate'] as double;
    if (cacheHitRate < 50.0) {
      // Preload commonly accessed pages
      // This would require additional logic to determine which pages to preload
      
      _performanceService.recordPerformanceMetric(
        PerformanceMetrics(
          operation: 'auto_optimize_rendering',
          duration: Duration.zero,
          additionalData: {
            'reason': 'low_cache_hit_rate',
            'cache_hit_rate': cacheHitRate,
          },
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}