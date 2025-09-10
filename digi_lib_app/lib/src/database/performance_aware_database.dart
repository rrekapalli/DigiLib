import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../services/performance_monitoring_service.dart';

/// Performance-aware database wrapper that monitors query performance
class PerformanceAwareDatabase {
  final Database _database;
  final PerformanceMonitoringService _performanceService;

  PerformanceAwareDatabase(this._database, this._performanceService);

  /// Execute a raw SQL query with performance monitoring
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    return _measureDatabaseOperation(
      sql,
      'SELECT',
      () => _database.rawQuery(sql, arguments),
    );
  }

  /// Execute a raw SQL insert with performance monitoring
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) async {
    return _measureDatabaseOperation(
      sql,
      'INSERT',
      () => _database.rawInsert(sql, arguments),
    );
  }

  /// Execute a raw SQL update with performance monitoring
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async {
    return _measureDatabaseOperation(
      sql,
      'UPDATE',
      () => _database.rawUpdate(sql, arguments),
    );
  }

  /// Execute a raw SQL delete with performance monitoring
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) async {
    return _measureDatabaseOperation(
      sql,
      'DELETE',
      () => _database.rawDelete(sql, arguments),
    );
  }

  /// Query with performance monitoring
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final sql = _buildQuerySql(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return _measureDatabaseOperation(
      sql,
      'SELECT',
      () => _database.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      ),
    );
  }

  /// Insert with performance monitoring
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final sql = 'INSERT INTO $table';
    
    return _measureDatabaseOperation(
      sql,
      'INSERT',
      () => _database.insert(
        table,
        values,
        nullColumnHack: nullColumnHack,
        conflictAlgorithm: conflictAlgorithm,
      ),
    );
  }

  /// Update with performance monitoring
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final sql = 'UPDATE $table SET ${values.keys.join(', ')}${where != null ? ' WHERE $where' : ''}';
    
    return _measureDatabaseOperation(
      sql,
      'UPDATE',
      () => _database.update(
        table,
        values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm,
      ),
    );
  }

  /// Delete with performance monitoring
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final sql = 'DELETE FROM $table${where != null ? ' WHERE $where' : ''}';
    
    return _measureDatabaseOperation(
      sql,
      'DELETE',
      () => _database.delete(table, where: where, whereArgs: whereArgs),
    );
  }

  /// Execute batch operations with performance monitoring
  Future<List<Object?>> batch(
    List<BatchOperation> operations,
  ) async {
    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();
    
    try {
      final batch = _database.batch();
      
      for (final operation in operations) {
        switch (operation.type) {
          case BatchOperationType.insert:
            batch.insert(
              operation.table,
              operation.values!,
              conflictAlgorithm: operation.conflictAlgorithm,
            );
            break;
          case BatchOperationType.update:
            batch.update(
              operation.table,
              operation.values!,
              where: operation.where,
              whereArgs: operation.whereArgs,
              conflictAlgorithm: operation.conflictAlgorithm,
            );
            break;
          case BatchOperationType.delete:
            batch.delete(
              operation.table,
              where: operation.where,
              whereArgs: operation.whereArgs,
            );
            break;
          case BatchOperationType.rawInsert:
            batch.rawInsert(operation.sql!, operation.arguments);
            break;
          case BatchOperationType.rawUpdate:
            batch.rawUpdate(operation.sql!, operation.arguments);
            break;
          case BatchOperationType.rawDelete:
            batch.rawDelete(operation.sql!, operation.arguments);
            break;
        }
      }
      
      final results = await batch.commit();
      stopwatch.stop();
      
      _performanceService.recordDatabaseMetric(
        DatabaseMetrics(
          query: 'BATCH (${operations.length} operations)',
          duration: stopwatch.elapsed,
          resultCount: results.length,
          operation: 'BATCH',
          timestamp: startTime,
        ),
      );
      
      return results;
    } catch (e) {
      stopwatch.stop();
      
      _performanceService.recordDatabaseMetric(
        DatabaseMetrics(
          query: 'BATCH (${operations.length} operations) - FAILED',
          duration: stopwatch.elapsed,
          resultCount: null,
          operation: 'BATCH',
          timestamp: startTime,
        ),
      );
      
      rethrow;
    }
  }

  /// Execute a transaction with performance monitoring
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) async {
    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();
    
    try {
      final result = await _database.transaction(action, exclusive: exclusive);
      stopwatch.stop();
      
      _performanceService.recordDatabaseMetric(
        DatabaseMetrics(
          query: 'TRANSACTION',
          duration: stopwatch.elapsed,
          resultCount: null,
          operation: 'TRANSACTION',
          timestamp: startTime,
        ),
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      _performanceService.recordDatabaseMetric(
        DatabaseMetrics(
          query: 'TRANSACTION - FAILED',
          duration: stopwatch.elapsed,
          resultCount: null,
          operation: 'TRANSACTION',
          timestamp: startTime,
        ),
      );
      
      rethrow;
    }
  }

  /// Measure database operation performance
  Future<T> _measureDatabaseOperation<T>(
    String sql,
    String operation,
    Future<T> Function() databaseCall,
  ) async {
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
      }
      
      _performanceService.recordDatabaseMetric(
        DatabaseMetrics(
          query: _sanitizeQuery(sql),
          duration: stopwatch.elapsed,
          resultCount: resultCount,
          operation: operation,
          timestamp: startTime,
        ),
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      _performanceService.recordDatabaseMetric(
        DatabaseMetrics(
          query: '${_sanitizeQuery(sql)} - FAILED',
          duration: stopwatch.elapsed,
          resultCount: null,
          operation: operation,
          timestamp: startTime,
        ),
      );
      
      rethrow;
    }
  }

  /// Sanitize SQL query for logging (remove sensitive data)
  String _sanitizeQuery(String sql) {
    // Remove potential sensitive data from queries
    return sql
        .replaceAll(RegExp(r"'[^']*'"), "'***'")
        .replaceAll(RegExp(r'"[^"]*"'), '"***"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Build SQL query string for logging
  String _buildQuerySql(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) {
    final buffer = StringBuffer('SELECT ');
    
    if (distinct == true) {
      buffer.write('DISTINCT ');
    }
    
    if (columns != null && columns.isNotEmpty) {
      buffer.write(columns.join(', '));
    } else {
      buffer.write('*');
    }
    
    buffer.write(' FROM $table');
    
    if (where != null) {
      buffer.write(' WHERE $where');
    }
    
    if (groupBy != null) {
      buffer.write(' GROUP BY $groupBy');
    }
    
    if (having != null) {
      buffer.write(' HAVING $having');
    }
    
    if (orderBy != null) {
      buffer.write(' ORDER BY $orderBy');
    }
    
    if (limit != null) {
      buffer.write(' LIMIT $limit');
    }
    
    if (offset != null) {
      buffer.write(' OFFSET $offset');
    }
    
    return buffer.toString();
  }

  /// Get database performance statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      // Get database size
      final sizeResult = await _database.rawQuery('PRAGMA page_count');
      final pageSizeResult = await _database.rawQuery('PRAGMA page_size');
      
      final pageCount = sizeResult.first['page_count'] as int? ?? 0;
      final pageSize = pageSizeResult.first['page_size'] as int? ?? 0;
      final databaseSize = pageCount * pageSize;
      
      // Get table statistics
      final tables = await _database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      final tableStats = <String, Map<String, dynamic>>{};
      for (final table in tables) {
        final tableName = table['name'] as String;
        final countResult = await _database.rawQuery('SELECT COUNT(*) as count FROM $tableName');
        final count = countResult.first['count'] as int? ?? 0;
        
        tableStats[tableName] = {
          'row_count': count,
        };
      }
      
      return {
        'database_size_bytes': databaseSize,
        'page_count': pageCount,
        'page_size': pageSize,
        'table_stats': tableStats,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Close the database
  Future<void> close() async {
    await _database.close();
  }

  /// Get the underlying database instance
  Database get database => _database;
}

/// Batch operation definition
class BatchOperation {
  final BatchOperationType type;
  final String table;
  final Map<String, Object?>? values;
  final String? where;
  final List<Object?>? whereArgs;
  final ConflictAlgorithm? conflictAlgorithm;
  final String? sql;
  final List<Object?>? arguments;

  BatchOperation.insert(
    this.table,
    this.values, {
    this.conflictAlgorithm,
  })  : type = BatchOperationType.insert,
        where = null,
        whereArgs = null,
        sql = null,
        arguments = null;

  BatchOperation.update(
    this.table,
    this.values, {
    this.where,
    this.whereArgs,
    this.conflictAlgorithm,
  })  : type = BatchOperationType.update,
        sql = null,
        arguments = null;

  BatchOperation.delete(
    this.table, {
    this.where,
    this.whereArgs,
  })  : type = BatchOperationType.delete,
        values = null,
        conflictAlgorithm = null,
        sql = null,
        arguments = null;

  BatchOperation.rawInsert(
    this.sql,
    this.arguments,
  )   : type = BatchOperationType.rawInsert,
        table = '',
        values = null,
        where = null,
        whereArgs = null,
        conflictAlgorithm = null;

  BatchOperation.rawUpdate(
    this.sql,
    this.arguments,
  )   : type = BatchOperationType.rawUpdate,
        table = '',
        values = null,
        where = null,
        whereArgs = null,
        conflictAlgorithm = null;

  BatchOperation.rawDelete(
    this.sql,
    this.arguments,
  )   : type = BatchOperationType.rawDelete,
        table = '',
        values = null,
        where = null,
        whereArgs = null,
        conflictAlgorithm = null;
}

enum BatchOperationType {
  insert,
  update,
  delete,
  rawInsert,
  rawUpdate,
  rawDelete,
}