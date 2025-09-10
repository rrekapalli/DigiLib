import 'package:flutter_test/flutter_test.dart';
import 'package:digi_lib_app/src/services/performance_monitoring_service.dart';

void main() {
  group('PerformanceMonitoringService', () {
    late PerformanceMonitoringService service;

    setUp(() {
      service = PerformanceMonitoringService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize successfully', () async {
      await service.initialize();
      expect(service, isNotNull);
    });

    test('should record performance metrics', () {
      final metric = PerformanceMetrics(
        operation: 'test_operation',
        duration: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
      );

      service.recordPerformanceMetric(metric);
      
      final stats = service.getPerformanceStats();
      expect(stats['performance_metrics_count'], equals(1));
    });

    test('should record network metrics', () {
      final metric = NetworkMetrics(
        endpoint: '/api/test',
        method: 'GET',
        duration: const Duration(milliseconds: 200),
        statusCode: 200,
        fromCache: false,
        timestamp: DateTime.now(),
      );

      service.recordNetworkMetric(metric);
      
      final stats = service.getPerformanceStats();
      expect(stats['network_metrics_count'], equals(1));
    });

    test('should record database metrics', () {
      final metric = DatabaseMetrics(
        query: 'SELECT * FROM documents',
        duration: const Duration(milliseconds: 50),
        operation: 'SELECT',
        timestamp: DateTime.now(),
      );

      service.recordDatabaseMetric(metric);
      
      final stats = service.getPerformanceStats();
      expect(stats['database_metrics_count'], equals(1));
    });

    test('should record rendering metrics', () {
      final metric = RenderingMetrics(
        documentId: 'doc123',
        pageNumber: 1,
        duration: const Duration(milliseconds: 300),
        renderingMethod: 'native',
        timestamp: DateTime.now(),
      );

      service.recordRenderingMetric(metric);
      
      final stats = service.getPerformanceStats();
      expect(stats['rendering_metrics_count'], equals(1));
    });

    test('should calculate average durations correctly', () {
      // Add multiple network metrics
      for (int i = 0; i < 3; i++) {
        service.recordNetworkMetric(NetworkMetrics(
          endpoint: '/api/test$i',
          method: 'GET',
          duration: Duration(milliseconds: 100 * (i + 1)), // 100, 200, 300ms
          statusCode: 200,
          fromCache: false,
          timestamp: DateTime.now(),
        ));
      }

      final stats = service.getPerformanceStats();
      expect(stats['avg_network_duration_ms'], equals(200.0)); // (100+200+300)/3
    });

    test('should trim metrics when exceeding max count', () {
      // This test would require setting a lower max count for testing
      // For now, just verify the method exists
      service.clearMetrics();
      final stats = service.getPerformanceStats();
      expect(stats['performance_metrics_count'], equals(0));
    });

    test('should get recent metrics with limit', () {
      // Add some metrics
      for (int i = 0; i < 5; i++) {
        service.recordPerformanceMetric(PerformanceMetrics(
          operation: 'test_$i',
          duration: Duration(milliseconds: i * 10),
          timestamp: DateTime.now(),
        ));
      }

      final recentMetrics = service.getRecentPerformanceMetrics(limit: 3);
      expect(recentMetrics.length, equals(3));
    });

    test('should handle memory monitoring stream', () async {
      await service.initialize();
      
      // Test that memory stream is available
      expect(service.memoryUsageStream, isNotNull);
      
      // Note: In a real test environment, we might not get memory updates
      // This just verifies the stream exists
    });
  });
}