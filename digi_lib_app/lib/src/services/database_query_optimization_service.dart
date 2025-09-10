import 'dart:async';
import 'dart:collection';
import 'package:logging/logging.dart';
import 'performance_monitoring_service.dart';
import '../database/performance_aware_database.dart';

/// Database query optimization service
class DatabaseQueryOptimizationService {
  static final Logger _logger = Logger('DatabaseQueryOptimizationService');

  final PerformanceMonitoringService _performanceService;
  final PerformanceAwareDatabase _database;

  // Query analysis data
  final Map<String, QueryAnalysis> _queryAnalysis = {};
  final Queue<QueryExecution> _recentQueries = Queue<QueryExecution>();

  Timer? _analysisTimer;
  Timer? _optimizationTimer;

  // Configuration
  static const int maxRecentQueries = 1000;
  static const Duration analysisInterval = Duration(minutes: 2);
  static const Duration optimizationInterval = Duration(minutes: 10);
  static const int slowQueryThresholdMs = 100;
  static const int verySlowQueryThresholdMs = 500;

  final StreamController<QueryOptimizationEvent> _eventController =
      StreamController<QueryOptimizationEvent>.broadcast();

  DatabaseQueryOptimizationService(this._performanceService, this._database);

  /// Initialize the query optimization service
  Future<void> initialize() async {
    _logger.info('Initializing database query optimization service');

    _startPeriodicAnalysis();
    _startPeriodicOptimization();
  }

  /// Start periodic query analysis
  void _startPeriodicAnalysis() {
    _analysisTimer = Timer.periodic(analysisInterval, (timer) {
      _analyzeQueries();
    });
  }

  /// Start periodic optimization
  void _startPeriodicOptimization() {
    _optimizationTimer = Timer.periodic(optimizationInterval, (timer) {
      _performOptimization();
    });
  }

  /// Record query execution for analysis
  void recordQueryExecution(
    String query,
    Duration duration,
    int? resultCount,
    String operation,
  ) {
    final execution = QueryExecution(
      query: _normalizeQuery(query),
      duration: duration,
      resultCount: resultCount,
      operation: operation,
      timestamp: DateTime.now(),
    );

    _recentQueries.add(execution);

    // Trim recent queries if too many
    if (_recentQueries.length > maxRecentQueries) {
      _recentQueries.removeFirst();
    }

    // Update query analysis
    _updateQueryAnalysis(execution);

    // Check for immediate optimization opportunities
    if (duration.inMilliseconds > verySlowQueryThresholdMs) {
      _handleSlowQuery(execution);
    }
  }

  /// Normalize query for analysis (remove parameters, etc.)
  String _normalizeQuery(String query) {
    return query
        .replaceAll(RegExp(r"'[^']*'"), "'?'")
        .replaceAll(RegExp(r'"[^"]*"'), '"?"')
        .replaceAll(RegExp(r'\b\d+\b'), '?')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toUpperCase();
  }

  /// Update query analysis data
  void _updateQueryAnalysis(QueryExecution execution) {
    final normalizedQuery = execution.query;

    final analysis =
        _queryAnalysis[normalizedQuery] ??
        QueryAnalysis(
          query: normalizedQuery,
          operation: execution.operation,
          executionCount: 0,
          totalDuration: Duration.zero,
          minDuration: execution.duration,
          maxDuration: execution.duration,
          lastExecuted: execution.timestamp,
        );

    analysis.executionCount++;
    analysis.totalDuration += execution.duration;
    analysis.lastExecuted = execution.timestamp;

    if (execution.duration < analysis.minDuration) {
      analysis.minDuration = execution.duration;
    }
    if (execution.duration > analysis.maxDuration) {
      analysis.maxDuration = execution.duration;
    }

    if (execution.resultCount != null) {
      analysis.totalResultCount =
          (analysis.totalResultCount ?? 0) + execution.resultCount!;
    }

    _queryAnalysis[normalizedQuery] = analysis;
  }

  /// Handle slow query detection
  void _handleSlowQuery(QueryExecution execution) {
    _logger.warning(
      'Slow query detected: ${execution.operation} took ${execution.duration.inMilliseconds}ms',
    );

    _eventController.add(
      QueryOptimizationEvent(
        type: QueryEventType.slowQuery,
        query: execution.query,
        duration: execution.duration,
        message: 'Slow ${execution.operation} query detected',
        timestamp: execution.timestamp,
      ),
    );

    _performanceService.recordPerformanceMetric(
      PerformanceMetrics(
        operation: 'slow_query_detected',
        duration: execution.duration,
        additionalData: {
          'query_operation': execution.operation,
          'result_count': execution.resultCount,
          'query_hash': execution.query.hashCode.toString(),
        },
        timestamp: execution.timestamp,
      ),
    );
  }

  /// Analyze queries for optimization opportunities
  void _analyzeQueries() {
    final stopwatch = Stopwatch()..start();

    try {
      final analysis = _performQueryAnalysis();

      stopwatch.stop();

      _performanceService.recordPerformanceMetric(
        PerformanceMetrics(
          operation: 'query_analysis',
          duration: stopwatch.elapsed,
          additionalData: {
            'total_queries': _queryAnalysis.length,
            'slow_queries': analysis['slow_queries'],
            'frequent_queries': analysis['frequent_queries'],
            'optimization_opportunities':
                analysis['optimization_opportunities'],
          },
          timestamp: DateTime.now(),
        ),
      );

      if (analysis['optimization_opportunities'] > 0) {
        _eventController.add(
          QueryOptimizationEvent(
            type: QueryEventType.optimizationOpportunity,
            query: '',
            duration: Duration.zero,
            message:
                '${analysis['optimization_opportunities']} optimization opportunities found',
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      stopwatch.stop();
      _logger.warning('Query analysis failed: $e');
    }
  }

  /// Perform detailed query analysis
  Map<String, dynamic> _performQueryAnalysis() {
    int slowQueries = 0;
    int frequentQueries = 0;
    int optimizationOpportunities = 0;

    for (final analysis in _queryAnalysis.values) {
      final avgDuration =
          analysis.totalDuration.inMilliseconds / analysis.executionCount;

      // Check for slow queries
      if (avgDuration > slowQueryThresholdMs) {
        slowQueries++;

        if (analysis.executionCount > 10) {
          optimizationOpportunities++;
        }
      }

      // Check for frequent queries
      if (analysis.executionCount > 50) {
        frequentQueries++;

        // Frequent queries that are even slightly slow should be optimized
        if (avgDuration > 50) {
          optimizationOpportunities++;
        }
      }

      // Check for queries with high variance (inconsistent performance)
      final variance = _calculateDurationVariance(analysis);
      if (variance > 100) {
        // High variance in milliseconds
        optimizationOpportunities++;
      }
    }

    return {
      'slow_queries': slowQueries,
      'frequent_queries': frequentQueries,
      'optimization_opportunities': optimizationOpportunities,
      'total_unique_queries': _queryAnalysis.length,
    };
  }

  /// Calculate duration variance for a query
  double _calculateDurationVariance(QueryAnalysis analysis) {
    if (analysis.executionCount < 2) return 0.0;

    final minMs = analysis.minDuration.inMilliseconds.toDouble();
    final maxMs = analysis.maxDuration.inMilliseconds.toDouble();

    // Simple variance approximation using min/max
    return (maxMs - minMs) / 2;
  }

  /// Perform database optimization
  Future<void> _performOptimization() async {
    final stopwatch = Stopwatch()..start();

    try {
      final optimizations = await _identifyOptimizations();

      if (optimizations.isNotEmpty) {
        await _applyOptimizations(optimizations);
      }

      stopwatch.stop();

      _performanceService.recordPerformanceMetric(
        PerformanceMetrics(
          operation: 'database_optimization',
          duration: stopwatch.elapsed,
          additionalData: {'optimizations_applied': optimizations.length},
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      stopwatch.stop();
      _logger.warning('Database optimization failed: $e');
    }
  }

  /// Identify optimization opportunities
  Future<List<DatabaseOptimization>> _identifyOptimizations() async {
    final optimizations = <DatabaseOptimization>[];

    // Analyze query patterns
    for (final analysis in _queryAnalysis.values) {
      final avgDuration =
          analysis.totalDuration.inMilliseconds / analysis.executionCount;

      // Suggest index for slow SELECT queries
      if (analysis.operation == 'SELECT' &&
          avgDuration > slowQueryThresholdMs &&
          analysis.executionCount > 5) {
        final indexSuggestion = _suggestIndex(analysis.query);
        if (indexSuggestion != null) {
          optimizations.add(
            DatabaseOptimization(
              type: OptimizationType.createIndex,
              query: analysis.query,
              suggestion: indexSuggestion,
              priority: avgDuration > verySlowQueryThresholdMs
                  ? OptimizationPriority.high
                  : OptimizationPriority.medium,
              estimatedImpact: _estimateIndexImpact(analysis),
            ),
          );
        }
      }

      // Suggest query rewrite for inefficient patterns
      final rewriteSuggestion = _suggestQueryRewrite(analysis.query);
      if (rewriteSuggestion != null) {
        optimizations.add(
          DatabaseOptimization(
            type: OptimizationType.rewriteQuery,
            query: analysis.query,
            suggestion: rewriteSuggestion,
            priority: OptimizationPriority.medium,
            estimatedImpact: 'Potential 20-50% performance improvement',
          ),
        );
      }
    }

    // Check for missing indexes on frequently accessed tables
    final tableAnalysis = await _analyzeTableAccess();
    for (final suggestion in tableAnalysis) {
      optimizations.add(suggestion);
    }

    return optimizations;
  }

  /// Suggest index creation for a query
  String? _suggestIndex(String query) {
    // Simple heuristics for index suggestions
    if (query.contains('WHERE') && query.contains('=')) {
      // Extract table and column from WHERE clause
      final whereMatch = RegExp(r'WHERE\s+(\w+)\.?(\w+)\s*=').firstMatch(query);
      if (whereMatch != null) {
        final column = whereMatch.group(2);
        final tableMatch = RegExp(r'FROM\s+(\w+)').firstMatch(query);
        if (tableMatch != null) {
          final table = tableMatch.group(1);
          return 'CREATE INDEX IF NOT EXISTS idx_${table}_$column ON $table($column)';
        }
      }
    }

    if (query.contains('ORDER BY')) {
      // Suggest index for ORDER BY columns
      final orderMatch = RegExp(r'ORDER BY\s+(\w+)').firstMatch(query);
      if (orderMatch != null) {
        final column = orderMatch.group(1);
        final tableMatch = RegExp(r'FROM\s+(\w+)').firstMatch(query);
        if (tableMatch != null) {
          final table = tableMatch.group(1);
          return 'CREATE INDEX IF NOT EXISTS idx_${table}_${column}_order ON $table($column)';
        }
      }
    }

    return null;
  }

  /// Suggest query rewrite
  String? _suggestQueryRewrite(String query) {
    // Check for SELECT * usage
    if (query.contains('SELECT *')) {
      return 'Consider selecting only needed columns instead of SELECT *';
    }

    // Check for LIKE with leading wildcard
    if (query.contains("LIKE '%")) {
      return 'Avoid LIKE patterns starting with % as they cannot use indexes';
    }

    // Check for OR conditions that could be rewritten
    if (query.contains(' OR ')) {
      return 'Consider rewriting OR conditions as UNION for better performance';
    }

    return null;
  }

  /// Estimate impact of index creation
  String _estimateIndexImpact(QueryAnalysis analysis) {
    final avgDuration =
        analysis.totalDuration.inMilliseconds / analysis.executionCount;

    if (avgDuration > verySlowQueryThresholdMs) {
      return 'High impact: Potential 70-90% performance improvement';
    } else if (avgDuration > slowQueryThresholdMs) {
      return 'Medium impact: Potential 40-70% performance improvement';
    } else {
      return 'Low impact: Potential 10-30% performance improvement';
    }
  }

  /// Analyze table access patterns
  Future<List<DatabaseOptimization>> _analyzeTableAccess() async {
    final optimizations = <DatabaseOptimization>[];

    try {
      // Get table statistics
      final tables = await _database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      for (final table in tables) {
        final tableName = table['name'] as String;

        // Check if table has indexes
        final indexes = await _database.rawQuery(
          "PRAGMA index_list('$tableName')",
        );

        // If table has no indexes and is frequently accessed, suggest primary key index
        if (indexes.isEmpty) {
          final accessCount = _getTableAccessCount(tableName);
          if (accessCount > 20) {
            optimizations.add(
              DatabaseOptimization(
                type: OptimizationType.createIndex,
                query: 'TABLE $tableName',
                suggestion:
                    'CREATE INDEX IF NOT EXISTS idx_${tableName}_id ON $tableName(id)',
                priority: OptimizationPriority.medium,
                estimatedImpact: 'Improve table scan performance',
              ),
            );
          }
        }
      }
    } catch (e) {
      _logger.warning('Table analysis failed: $e');
    }

    return optimizations;
  }

  /// Get table access count from query analysis
  int _getTableAccessCount(String tableName) {
    int count = 0;
    for (final analysis in _queryAnalysis.values) {
      if (analysis.query.contains('FROM $tableName') ||
          analysis.query.contains('UPDATE $tableName') ||
          analysis.query.contains('INSERT INTO $tableName')) {
        count += analysis.executionCount;
      }
    }
    return count;
  }

  /// Apply database optimizations
  Future<void> _applyOptimizations(
    List<DatabaseOptimization> optimizations,
  ) async {
    for (final optimization in optimizations) {
      try {
        if (optimization.type == OptimizationType.createIndex) {
          await _database.rawQuery(optimization.suggestion);

          _eventController.add(
            QueryOptimizationEvent(
              type: QueryEventType.optimizationApplied,
              query: optimization.query,
              duration: Duration.zero,
              message: 'Applied optimization: ${optimization.suggestion}',
              timestamp: DateTime.now(),
            ),
          );

          _logger.info(
            'Applied database optimization: ${optimization.suggestion}',
          );
        }
      } catch (e) {
        _logger.warning(
          'Failed to apply optimization ${optimization.suggestion}: $e',
        );
      }
    }
  }

  /// Get query performance statistics
  Map<String, dynamic> getQueryStatistics() {
    if (_queryAnalysis.isEmpty) {
      return {
        'total_queries': 0,
        'slow_queries': 0,
        'average_duration_ms': 0.0,
      };
    }

    int totalExecutions = 0;
    Duration totalDuration = Duration.zero;
    int slowQueries = 0;

    for (final analysis in _queryAnalysis.values) {
      totalExecutions += analysis.executionCount;
      totalDuration += analysis.totalDuration;

      final avgDuration =
          analysis.totalDuration.inMilliseconds / analysis.executionCount;
      if (avgDuration > slowQueryThresholdMs) {
        slowQueries++;
      }
    }

    final avgDuration = totalExecutions > 0
        ? totalDuration.inMilliseconds / totalExecutions
        : 0.0;

    return {
      'total_unique_queries': _queryAnalysis.length,
      'total_executions': totalExecutions,
      'slow_queries': slowQueries,
      'average_duration_ms': avgDuration,
      'recent_queries_count': _recentQueries.length,
      'optimization_opportunities': _identifyOptimizations().then(
        (opts) => opts.length,
      ),
    };
  }

  /// Get optimization events stream
  Stream<QueryOptimizationEvent> get events => _eventController.stream;

  /// Get top slow queries
  List<QueryAnalysis> getTopSlowQueries({int limit = 10}) {
    final queries = _queryAnalysis.values.toList();
    queries.sort((a, b) {
      final avgA = a.totalDuration.inMilliseconds / a.executionCount;
      final avgB = b.totalDuration.inMilliseconds / b.executionCount;
      return avgB.compareTo(avgA);
    });

    return queries.take(limit).toList();
  }

  /// Get most frequent queries
  List<QueryAnalysis> getMostFrequentQueries({int limit = 10}) {
    final queries = _queryAnalysis.values.toList();
    queries.sort((a, b) => b.executionCount.compareTo(a.executionCount));

    return queries.take(limit).toList();
  }

  /// Clear query analysis data
  void clearAnalysisData() {
    _queryAnalysis.clear();
    _recentQueries.clear();

    _performanceService.recordPerformanceMetric(
      PerformanceMetrics(
        operation: 'clear_query_analysis',
        duration: Duration.zero,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Dispose resources
  void dispose() {
    _analysisTimer?.cancel();
    _optimizationTimer?.cancel();
    _eventController.close();
  }
}

/// Query execution record
class QueryExecution {
  final String query;
  final Duration duration;
  final int? resultCount;
  final String operation;
  final DateTime timestamp;

  QueryExecution({
    required this.query,
    required this.duration,
    this.resultCount,
    required this.operation,
    required this.timestamp,
  });
}

/// Query analysis data
class QueryAnalysis {
  final String query;
  final String operation;
  int executionCount;
  Duration totalDuration;
  Duration minDuration;
  Duration maxDuration;
  DateTime lastExecuted;
  int? totalResultCount;

  QueryAnalysis({
    required this.query,
    required this.operation,
    required this.executionCount,
    required this.totalDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.lastExecuted,
    this.totalResultCount,
  });

  double get averageDurationMs => totalDuration.inMilliseconds / executionCount;

  Map<String, dynamic> toJson() => {
    'query': query,
    'operation': operation,
    'execution_count': executionCount,
    'average_duration_ms': averageDurationMs,
    'min_duration_ms': minDuration.inMilliseconds,
    'max_duration_ms': maxDuration.inMilliseconds,
    'last_executed': lastExecuted.toIso8601String(),
    'total_result_count': totalResultCount,
  };
}

/// Database optimization suggestion
class DatabaseOptimization {
  final OptimizationType type;
  final String query;
  final String suggestion;
  final OptimizationPriority priority;
  final String estimatedImpact;

  DatabaseOptimization({
    required this.type,
    required this.query,
    required this.suggestion,
    required this.priority,
    required this.estimatedImpact,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'query': query,
    'suggestion': suggestion,
    'priority': priority.toString(),
    'estimated_impact': estimatedImpact,
  };
}

/// Query optimization event
class QueryOptimizationEvent {
  final QueryEventType type;
  final String query;
  final Duration duration;
  final String message;
  final DateTime timestamp;

  QueryOptimizationEvent({
    required this.type,
    required this.query,
    required this.duration,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'query': query,
    'duration_ms': duration.inMilliseconds,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
  };
}

enum OptimizationType { createIndex, rewriteQuery, addConstraint }

enum OptimizationPriority { low, medium, high }

enum QueryEventType { slowQuery, optimizationOpportunity, optimizationApplied }
