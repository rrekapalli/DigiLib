import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/performance_monitoring_service.dart';
import '../services/memory_optimization_service.dart';
import '../services/performance_integration_service.dart';
import '../services/network_cache_optimization_service.dart';
import '../services/database_query_optimization_service.dart';
import '../services/performance_aware_rendering_service.dart';
import '../services/page_rendering_service.dart';
import '../database/performance_aware_database.dart';
import '../network/performance_aware_api_client.dart';

/// Provider for performance monitoring service
final performanceMonitoringServiceProvider = Provider<PerformanceMonitoringService>((ref) {
  final service = PerformanceMonitoringService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for memory optimization service
final memoryOptimizationServiceProvider = Provider<MemoryOptimizationService>((ref) {
  final performanceService = ref.watch(performanceMonitoringServiceProvider);
  final service = MemoryOptimizationService(performanceService);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for network cache optimization service
final networkCacheOptimizationServiceProvider = Provider<NetworkCacheOptimizationService>((ref) {
  final performanceService = ref.watch(performanceMonitoringServiceProvider);
  final service = NetworkCacheOptimizationService(performanceService);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for database query optimization service
final databaseQueryOptimizationServiceProvider = Provider<DatabaseQueryOptimizationService>((ref) {
  final performanceService = ref.watch(performanceMonitoringServiceProvider);
  // Note: This would need to be integrated with the actual database provider
  // For now, we'll create a placeholder that would be replaced with actual database integration
  throw UnimplementedError('Database query optimization requires database integration');
});

/// Provider for performance-aware rendering service
final performanceAwareRenderingServiceProvider = Provider<PerformanceAwareRenderingService>((ref) {
  final performanceService = ref.watch(performanceMonitoringServiceProvider);
  // Note: This would need to be integrated with the actual page rendering service
  // For now, we'll create a placeholder that would be replaced with actual rendering service integration
  throw UnimplementedError('Performance-aware rendering requires page rendering service integration');
});

/// Provider for performance integration service
final performanceIntegrationServiceProvider = Provider<PerformanceIntegrationService>((ref) {
  final performanceService = ref.watch(performanceMonitoringServiceProvider);
  final memoryService = ref.watch(memoryOptimizationServiceProvider);
  
  final service = PerformanceIntegrationService(
    performanceService,
    memoryService,
  );
  
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for performance dashboard data
final performanceDashboardProvider = Provider<Map<String, dynamic>>((ref) {
  final integrationService = ref.watch(performanceIntegrationServiceProvider);
  return integrationService.getPerformanceDashboard();
});

/// Provider for performance statistics
final performanceStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final performanceService = ref.watch(performanceMonitoringServiceProvider);
  return performanceService.getPerformanceStats();
});

/// Provider for memory statistics
final memoryStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final memoryService = ref.watch(memoryOptimizationServiceProvider);
  return memoryService.getMemoryStats();
});

/// Provider for network cache statistics
final networkCacheStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final cacheService = ref.watch(networkCacheOptimizationServiceProvider);
  return cacheService.getCacheStatistics();
});

/// Stream provider for performance reports
final performanceReportsProvider = StreamProvider<PerformanceReport>((ref) {
  final integrationService = ref.watch(performanceIntegrationServiceProvider);
  return integrationService.reports;
});

/// Stream provider for memory optimization events
final memoryEventsProvider = StreamProvider<MemoryOptimizationEvent>((ref) {
  final memoryService = ref.watch(memoryOptimizationServiceProvider);
  return memoryService.events;
});

/// Stream provider for network cache events
final networkCacheEventsProvider = StreamProvider<CacheEvent>((ref) {
  final cacheService = ref.watch(networkCacheOptimizationServiceProvider);
  return cacheService.events;
});

/// Stream provider for memory usage
final memoryUsageProvider = StreamProvider<MemoryInfo>((ref) {
  final performanceService = ref.watch(performanceMonitoringServiceProvider);
  return performanceService.memoryUsageStream;
});

/// Provider for performance optimization actions
final performanceOptimizationProvider = Provider<PerformanceOptimizationActions>((ref) {
  final integrationService = ref.watch(performanceIntegrationServiceProvider);
  final memoryService = ref.watch(memoryOptimizationServiceProvider);
  final cacheService = ref.watch(networkCacheOptimizationServiceProvider);
  
  return PerformanceOptimizationActions(
    integrationService: integrationService,
    memoryService: memoryService,
    cacheService: cacheService,
  );
});

/// Performance optimization actions
class PerformanceOptimizationActions {
  final PerformanceIntegrationService integrationService;
  final MemoryOptimizationService memoryService;
  final NetworkCacheOptimizationService cacheService;

  PerformanceOptimizationActions({
    required this.integrationService,
    required this.memoryService,
    required this.cacheService,
  });

  /// Optimize overall performance
  Future<void> optimizePerformance({bool aggressive = false}) async {
    await integrationService.optimizePerformance(aggressive: aggressive);
  }

  /// Optimize memory usage
  Future<void> optimizeMemory({bool aggressive = false}) async {
    await memoryService.optimizeMemory(aggressive: aggressive);
  }

  /// Optimize network cache
  Future<void> optimizeNetworkCache() async {
    await cacheService.optimizeCache();
  }

  /// Clear network cache
  Future<void> clearNetworkCache() async {
    await cacheService.clearCache();
  }

  /// Export performance data
  Map<String, dynamic> exportPerformanceData({
    DateTime? since,
    int? limit,
  }) {
    return integrationService.exportPerformanceData(
      since: since,
      limit: limit,
    );
  }

  /// Get comprehensive performance dashboard
  Map<String, dynamic> getPerformanceDashboard() {
    return integrationService.getPerformanceDashboard();
  }
}

/// Provider for performance initialization
final performanceInitializationProvider = FutureProvider<void>((ref) async {
  final performanceService = ref.watch(performanceMonitoringServiceProvider);
  final memoryService = ref.watch(memoryOptimizationServiceProvider);
  final cacheService = ref.watch(networkCacheOptimizationServiceProvider);
  final integrationService = ref.watch(performanceIntegrationServiceProvider);

  // Initialize all performance services
  await performanceService.initialize();
  await memoryService.initialize();
  await cacheService.initialize();
  await integrationService.initialize();
});

/// Provider for performance health score
final performanceHealthScoreProvider = Provider<int>((ref) {
  final dashboard = ref.watch(performanceDashboardProvider);
  return dashboard['health_score'] as int? ?? 0;
});

/// Provider for performance recommendations
final performanceRecommendationsProvider = Provider<List<PerformanceRecommendation>>((ref) {
  final dashboard = ref.watch(performanceDashboardProvider);
  final recommendations = dashboard['recommendations'] as List<dynamic>? ?? [];
  
  return recommendations
      .map((r) => PerformanceRecommendation(
            type: RecommendationType.values.firstWhere(
              (t) => t.toString() == r['type'],
              orElse: () => RecommendationType.general,
            ),
            priority: RecommendationPriority.values.firstWhere(
              (p) => p.toString() == r['priority'],
              orElse: () => RecommendationPriority.low,
            ),
            title: r['title'] as String,
            description: r['description'] as String,
            action: r['action'] as String,
          ))
      .toList();
});

/// Provider for critical performance issues
final criticalPerformanceIssuesProvider = Provider<List<PerformanceRecommendation>>((ref) {
  final recommendations = ref.watch(performanceRecommendationsProvider);
  return recommendations
      .where((r) => r.priority == RecommendationPriority.critical)
      .toList();
});

/// Provider for performance monitoring configuration
final performanceConfigProvider = StateProvider<PerformanceConfig>((ref) {
  return PerformanceConfig();
});

/// Performance monitoring configuration
class PerformanceConfig {
  final bool enableMemoryMonitoring;
  final bool enableNetworkCaching;
  final bool enableDatabaseOptimization;
  final bool enableRenderingOptimization;
  final bool enableAutomaticOptimization;
  final Duration reportingInterval;
  final Duration optimizationInterval;

  PerformanceConfig({
    this.enableMemoryMonitoring = true,
    this.enableNetworkCaching = true,
    this.enableDatabaseOptimization = true,
    this.enableRenderingOptimization = true,
    this.enableAutomaticOptimization = true,
    this.reportingInterval = const Duration(minutes: 5),
    this.optimizationInterval = const Duration(minutes: 10),
  });

  PerformanceConfig copyWith({
    bool? enableMemoryMonitoring,
    bool? enableNetworkCaching,
    bool? enableDatabaseOptimization,
    bool? enableRenderingOptimization,
    bool? enableAutomaticOptimization,
    Duration? reportingInterval,
    Duration? optimizationInterval,
  }) {
    return PerformanceConfig(
      enableMemoryMonitoring: enableMemoryMonitoring ?? this.enableMemoryMonitoring,
      enableNetworkCaching: enableNetworkCaching ?? this.enableNetworkCaching,
      enableDatabaseOptimization: enableDatabaseOptimization ?? this.enableDatabaseOptimization,
      enableRenderingOptimization: enableRenderingOptimization ?? this.enableRenderingOptimization,
      enableAutomaticOptimization: enableAutomaticOptimization ?? this.enableAutomaticOptimization,
      reportingInterval: reportingInterval ?? this.reportingInterval,
      optimizationInterval: optimizationInterval ?? this.optimizationInterval,
    );
  }
}