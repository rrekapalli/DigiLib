import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import 'performance_monitoring_service.dart';
import 'memory_optimization_service.dart';

/// Service that integrates all performance monitoring components
class PerformanceIntegrationService {
  static final Logger _logger = Logger('PerformanceIntegrationService');
  
  final PerformanceMonitoringService _performanceService;
  final MemoryOptimizationService _memoryService;
  
  Timer? _reportingTimer;
  Timer? _optimizationTimer;
  
  // Configuration
  static const Duration reportingInterval = Duration(minutes: 5);
  static const Duration optimizationInterval = Duration(minutes: 10);
  
  final StreamController<PerformanceReport> _reportController = 
      StreamController<PerformanceReport>.broadcast();

  PerformanceIntegrationService(
    this._performanceService,
    this._memoryService,
  );

  /// Initialize the performance integration service
  Future<void> initialize() async {
    _logger.info('Initializing performance integration service');
    
    await _performanceService.initialize();
    await _memoryService.initialize();
    
    _startPeriodicReporting();
    _startPeriodicOptimization();
    
    // Listen to memory events for immediate action
    _memoryService.events.listen(_handleMemoryEvent);
  }

  /// Start periodic performance reporting
  void _startPeriodicReporting() {
    _reportingTimer = Timer.periodic(reportingInterval, (timer) {
      _generatePerformanceReport();
    });
  }

  /// Start periodic optimization
  void _startPeriodicOptimization() {
    _optimizationTimer = Timer.periodic(optimizationInterval, (timer) {
      _performAutomaticOptimization();
    });
  }

  /// Generate comprehensive performance report
  void _generatePerformanceReport() {
    try {
      final performanceStats = _performanceService.getPerformanceStats();
      final memoryStats = _memoryService.getMemoryStats();
      
      final report = PerformanceReport(
        timestamp: DateTime.now(),
        performanceStats: performanceStats,
        memoryStats: memoryStats,
        networkMetrics: _performanceService.getRecentNetworkMetrics(limit: 50),
        databaseMetrics: _performanceService.getRecentDatabaseMetrics(limit: 50),
        renderingMetrics: _performanceService.getRecentRenderingMetrics(limit: 50),
        recommendations: _generateRecommendations(performanceStats, memoryStats),
      );
      
      _reportController.add(report);
      _logger.info('Performance report generated: ${report.summary}');
    } catch (e) {
      _logger.warning('Failed to generate performance report: $e');
    }
  }

  /// Generate performance recommendations
  List<PerformanceRecommendation> _generateRecommendations(
    Map<String, dynamic> performanceStats,
    Map<String, dynamic> memoryStats,
  ) {
    final recommendations = <PerformanceRecommendation>[];
    
    // Network performance recommendations
    final avgNetworkDuration = performanceStats['avg_network_duration_ms'] as double? ?? 0.0;
    if (avgNetworkDuration > 3000) {
      recommendations.add(
        PerformanceRecommendation(
          type: RecommendationType.network,
          priority: RecommendationPriority.high,
          title: 'Slow Network Requests',
          description: 'Average network request time is ${avgNetworkDuration.toStringAsFixed(0)}ms',
          action: 'Consider enabling request caching or optimizing API endpoints',
        ),
      );
    }
    
    // Database performance recommendations
    final avgDatabaseDuration = performanceStats['avg_database_duration_ms'] as double? ?? 0.0;
    if (avgDatabaseDuration > 100) {
      recommendations.add(
        PerformanceRecommendation(
          type: RecommendationType.database,
          priority: RecommendationPriority.medium,
          title: 'Slow Database Queries',
          description: 'Average database query time is ${avgDatabaseDuration.toStringAsFixed(0)}ms',
          action: 'Consider adding database indexes or optimizing queries',
        ),
      );
    }
    
    // Memory recommendations
    final memoryPressure = memoryStats['memory_pressure'] as String? ?? 'low';
    if (memoryPressure == 'high' || memoryPressure == 'critical') {
      recommendations.add(
        PerformanceRecommendation(
          type: RecommendationType.memory,
          priority: memoryPressure == 'critical' 
              ? RecommendationPriority.critical 
              : RecommendationPriority.high,
          title: 'High Memory Usage',
          description: 'Memory pressure is $memoryPressure',
          action: 'Clear caches or reduce concurrent operations',
        ),
      );
    }
    
    // Rendering performance recommendations
    final avgRenderingDuration = performanceStats['avg_rendering_duration_ms'] as double? ?? 0.0;
    if (avgRenderingDuration > 1500) {
      recommendations.add(
        PerformanceRecommendation(
          type: RecommendationType.rendering,
          priority: RecommendationPriority.medium,
          title: 'Slow Page Rendering',
          description: 'Average rendering time is ${avgRenderingDuration.toStringAsFixed(0)}ms',
          action: 'Consider reducing DPI or enabling page preloading',
        ),
      );
    }
    
    // Slow operations recommendations
    final slowOperationsCount = performanceStats['slow_operations_count'] as int? ?? 0;
    if (slowOperationsCount > 5) {
      recommendations.add(
        PerformanceRecommendation(
          type: RecommendationType.general,
          priority: RecommendationPriority.medium,
          title: 'Multiple Slow Operations',
          description: '$slowOperationsCount slow operations detected',
          action: 'Review recent operations and optimize bottlenecks',
        ),
      );
    }
    
    return recommendations;
  }

  /// Handle memory optimization events
  void _handleMemoryEvent(MemoryOptimizationEvent event) {
    _logger.info('Memory event: ${event.type} - ${event.message}');
    
    if (event.type == MemoryEventType.critical) {
      // Trigger immediate performance optimization
      _performEmergencyOptimization();
    }
  }

  /// Perform automatic optimization based on metrics
  Future<void> _performAutomaticOptimization() async {
    try {
      final performanceStats = _performanceService.getPerformanceStats();
      final memoryStats = _memoryService.getMemoryStats();
      
      // Check if optimization is needed
      final needsOptimization = _shouldOptimize(performanceStats, memoryStats);
      
      if (needsOptimization) {
        _logger.info('Performing automatic performance optimization');
        
        // Clear old metrics to free memory
        if (performanceStats['performance_metrics_count'] as int > 500) {
          _performanceService.clearMetrics();
        }
        
        // Optimize memory if pressure is high
        final memoryPressure = memoryStats['memory_pressure'] as String? ?? 'low';
        if (memoryPressure == 'high' || memoryPressure == 'critical') {
          await _memoryService.optimizeMemory(aggressive: memoryPressure == 'critical');
        }
        
        _performanceService.recordPerformanceMetric(
          PerformanceMetrics(
            operation: 'automatic_optimization',
            duration: Duration.zero,
            additionalData: {
              'memory_pressure': memoryPressure,
              'metrics_count': performanceStats['performance_metrics_count'],
            },
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      _logger.warning('Automatic optimization failed: $e');
    }
  }

  /// Perform emergency optimization for critical situations
  Future<void> _performEmergencyOptimization() async {
    try {
      _logger.warning('Performing emergency performance optimization');
      
      // Clear all metrics immediately
      _performanceService.clearMetrics();
      
      // Aggressive memory cleanup
      await _memoryService.optimizeMemory(aggressive: true);
      
      _performanceService.recordPerformanceMetric(
        PerformanceMetrics(
          operation: 'emergency_optimization',
          duration: Duration.zero,
          additionalData: {
            'trigger': 'critical_memory_pressure',
          },
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      _logger.severe('Emergency optimization failed: $e');
    }
  }

  /// Determine if optimization is needed
  bool _shouldOptimize(
    Map<String, dynamic> performanceStats,
    Map<String, dynamic> memoryStats,
  ) {
    // Check memory pressure
    final memoryPressure = memoryStats['memory_pressure'] as String? ?? 'low';
    if (memoryPressure == 'high' || memoryPressure == 'critical') {
      return true;
    }
    
    // Check metrics count
    final metricsCount = performanceStats['performance_metrics_count'] as int? ?? 0;
    if (metricsCount > 500) {
      return true;
    }
    
    // Check slow operations
    final slowOperationsCount = performanceStats['slow_operations_count'] as int? ?? 0;
    if (slowOperationsCount > 10) {
      return true;
    }
    
    return false;
  }

  /// Get comprehensive performance dashboard data
  Map<String, dynamic> getPerformanceDashboard() {
    final performanceStats = _performanceService.getPerformanceStats();
    final memoryStats = _memoryService.getMemoryStats();
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'performance': performanceStats,
      'memory': memoryStats,
      'system_info': _getSystemInfo(),
      'health_score': _calculateHealthScore(performanceStats, memoryStats),
      'recommendations': _generateRecommendations(performanceStats, memoryStats)
          .map((r) => r.toJson())
          .toList(),
    };
  }

  /// Get system information
  Map<String, dynamic> _getSystemInfo() {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'dart_version': Platform.version,
      'number_of_processors': Platform.numberOfProcessors,
      'executable': Platform.executable,
    };
  }

  /// Calculate overall health score (0-100)
  int _calculateHealthScore(
    Map<String, dynamic> performanceStats,
    Map<String, dynamic> memoryStats,
  ) {
    int score = 100;
    
    // Deduct points for slow operations
    final slowOperationsCount = performanceStats['slow_operations_count'] as int? ?? 0;
    score -= (slowOperationsCount * 2).clamp(0, 30);
    
    // Deduct points for high memory usage
    final memoryPressure = memoryStats['memory_pressure'] as String? ?? 'low';
    switch (memoryPressure) {
      case 'critical':
        score -= 40;
        break;
      case 'high':
        score -= 25;
        break;
      case 'moderate':
        score -= 10;
        break;
    }
    
    // Deduct points for slow network requests
    final avgNetworkDuration = performanceStats['avg_network_duration_ms'] as double? ?? 0.0;
    if (avgNetworkDuration > 5000) {
      score -= 20;
    } else if (avgNetworkDuration > 3000) {
      score -= 10;
    }
    
    // Deduct points for slow database queries
    final avgDatabaseDuration = performanceStats['avg_database_duration_ms'] as double? ?? 0.0;
    if (avgDatabaseDuration > 200) {
      score -= 15;
    } else if (avgDatabaseDuration > 100) {
      score -= 8;
    }
    
    return score.clamp(0, 100);
  }

  /// Export performance data for analysis
  Map<String, dynamic> exportPerformanceData({
    DateTime? since,
    int? limit,
  }) {
    return {
      'export_timestamp': DateTime.now().toIso8601String(),
      'since': since?.toIso8601String(),
      'limit': limit,
      'performance_metrics': _performanceService.getRecentPerformanceMetrics(
        limit: limit ?? 1000,
      ).map((m) => m.toJson()).toList(),
      'network_metrics': _performanceService.getRecentNetworkMetrics(
        limit: limit ?? 1000,
      ).map((m) => m.toJson()).toList(),
      'database_metrics': _performanceService.getRecentDatabaseMetrics(
        limit: limit ?? 1000,
      ).map((m) => m.toJson()).toList(),
      'rendering_metrics': _performanceService.getRecentRenderingMetrics(
        limit: limit ?? 1000,
      ).map((m) => m.toJson()).toList(),
      'system_info': _getSystemInfo(),
    };
  }

  /// Get performance reports stream
  Stream<PerformanceReport> get reports => _reportController.stream;

  /// Manually trigger performance optimization
  Future<void> optimizePerformance({bool aggressive = false}) async {
    if (aggressive) {
      await _performEmergencyOptimization();
    } else {
      await _performAutomaticOptimization();
    }
  }

  /// Dispose resources
  void dispose() {
    _reportingTimer?.cancel();
    _optimizationTimer?.cancel();
    _reportController.close();
    _performanceService.dispose();
    _memoryService.dispose();
  }
}

/// Comprehensive performance report
class PerformanceReport {
  final DateTime timestamp;
  final Map<String, dynamic> performanceStats;
  final Map<String, dynamic> memoryStats;
  final List<NetworkMetrics> networkMetrics;
  final List<DatabaseMetrics> databaseMetrics;
  final List<RenderingMetrics> renderingMetrics;
  final List<PerformanceRecommendation> recommendations;

  PerformanceReport({
    required this.timestamp,
    required this.performanceStats,
    required this.memoryStats,
    required this.networkMetrics,
    required this.databaseMetrics,
    required this.renderingMetrics,
    required this.recommendations,
  });

  /// Get report summary
  String get summary {
    final criticalRecommendations = recommendations
        .where((r) => r.priority == RecommendationPriority.critical)
        .length;
    final highRecommendations = recommendations
        .where((r) => r.priority == RecommendationPriority.high)
        .length;
    
    return 'Performance Report: $criticalRecommendations critical, $highRecommendations high priority issues';
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'performance_stats': performanceStats,
    'memory_stats': memoryStats,
    'network_metrics_count': networkMetrics.length,
    'database_metrics_count': databaseMetrics.length,
    'rendering_metrics_count': renderingMetrics.length,
    'recommendations': recommendations.map((r) => r.toJson()).toList(),
    'summary': summary,
  };
}

/// Performance recommendation
class PerformanceRecommendation {
  final RecommendationType type;
  final RecommendationPriority priority;
  final String title;
  final String description;
  final String action;

  PerformanceRecommendation({
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'priority': priority.toString(),
    'title': title,
    'description': description,
    'action': action,
  };
}

enum RecommendationType {
  network,
  database,
  memory,
  rendering,
  general,
}

enum RecommendationPriority {
  low,
  medium,
  high,
  critical,
}