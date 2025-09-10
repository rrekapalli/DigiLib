import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/database_helper.dart';

/// Enum for job types
enum JobType {
  createBookmark,
  updateBookmark,
  deleteBookmark,
  createComment,
  updateComment,
  deleteComment,
  updateReadingProgress,
  deleteReadingProgress,
  createTag,
  deleteTag,
  addTagToDocument,
  removeTagFromDocument,
  createShare,
  updateShare,
  deleteShare,
  createLibrary,
  deleteLibrary,
  scanLibrary,
}

/// Enum for job status
enum JobStatus { pending, processing, completed, failed }

/// Model for a job in the queue
class Job {
  final String id;
  final JobType type;
  final Map<String, dynamic> payload;
  final JobStatus status;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
  final DateTime? scheduledAt;

  const Job({
    required this.id,
    required this.type,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
    this.scheduledAt,
  });

  Job copyWith({
    String? id,
    JobType? type,
    Map<String, dynamic>? payload,
    JobStatus? status,
    DateTime? createdAt,
    int? attempts,
    String? lastError,
    DateTime? scheduledAt,
  }) {
    return Job(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      scheduledAt: scheduledAt ?? this.scheduledAt,
    );
  }
}

/// Service for managing offline job queue
class JobQueueService {
  final DatabaseHelper _databaseHelper;
  Timer? _retryTimer;
  final StreamController<JobQueueStatus> _statusController =
      StreamController<JobQueueStatus>.broadcast();

  // Circuit breaker for database errors (to be implemented)

  JobQueueService({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance {
    _initializeRetryScheduler();
  }

  /// Stream of job queue status updates
  Stream<JobQueueStatus> get statusStream => _statusController.stream;

  /// Initialize automatic retry scheduler
  void _initializeRetryScheduler() {
    // Check for failed jobs every 60 seconds and retry with exponential backoff
    // Increased interval to reduce database access frequency
    _retryTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      await _processRetryableJobs();
    });
  }

  /// Add a new job to the queue
  Future<void> addJob(
    JobType type,
    Map<String, dynamic> payload, {
    DateTime? scheduledAt,
  }) async {
    try {
      final db = await _databaseHelper.database;
      final job = Job(
        id: _generateJobId(),
        type: type,
        payload: payload,
        status: JobStatus.pending,
        createdAt: DateTime.now(),
        scheduledAt: scheduledAt,
      );

      await db.insert(
        'jobs_queue',
        _jobToMap(job),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (e.toString().contains('journal_mode') ||
          e.toString().contains('WAL')) {
        // Database configuration error - skip this operation
        return;
      }
      debugPrint('Error adding job to queue: $e');
      rethrow;
    }
  }

  /// Get all pending jobs
  Future<List<Job>> getPendingJobs() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'jobs_queue',
      where: 'status = ? AND (scheduled_at IS NULL OR scheduled_at <= ?)',
      whereArgs: [JobStatus.pending.name, now],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => _mapToJob(map)).toList();
  }

  /// Get jobs by type
  Future<List<Job>> getJobsByType(JobType type) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'jobs_queue',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => _mapToJob(map)).toList();
  }

  /// Update job status
  Future<void> updateJobStatus(
    String jobId,
    JobStatus status, {
    String? error,
  }) async {
    final db = await _databaseHelper.database;
    final updateData = <String, dynamic>{'status': status.name};

    if (error != null) {
      updateData['last_error'] = error;
    }

    await db.update(
      'jobs_queue',
      updateData,
      where: 'id = ?',
      whereArgs: [jobId],
    );
  }

  /// Increment job attempts
  Future<void> incrementJobAttempts(String jobId, {String? error}) async {
    final db = await _databaseHelper.database;
    await db.rawUpdate(
      'UPDATE jobs_queue SET attempts = attempts + 1, last_error = ? WHERE id = ?',
      [error, jobId],
    );
  }

  /// Mark job as completed and remove from queue
  Future<void> completeJob(String jobId) async {
    final db = await _databaseHelper.database;
    await db.delete('jobs_queue', where: 'id = ?', whereArgs: [jobId]);
  }

  /// Mark job as failed
  Future<void> failJob(String jobId, String error) async {
    final db = await _databaseHelper.database;
    await db.update(
      'jobs_queue',
      {'status': JobStatus.failed.name, 'last_error': error},
      where: 'id = ?',
      whereArgs: [jobId],
    );
  }

  /// Retry failed jobs (reset to pending status)
  Future<void> retryFailedJobs() async {
    final db = await _databaseHelper.database;
    await db.update(
      'jobs_queue',
      {'status': JobStatus.pending.name},
      where: 'status = ?',
      whereArgs: [JobStatus.failed.name],
    );
  }

  /// Clear completed jobs older than specified duration
  Future<void> clearOldJobs({Duration age = const Duration(days: 7)}) async {
    final db = await _databaseHelper.database;
    final cutoffTime = DateTime.now().subtract(age).millisecondsSinceEpoch;

    await db.delete(
      'jobs_queue',
      where: 'status = ? AND created_at < ?',
      whereArgs: [JobStatus.completed.name, cutoffTime],
    );
  }

  /// Get job count by status
  Future<int> getJobCount(JobStatus status) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM jobs_queue WHERE status = ?',
      [status.name],
    );
    return result.first['count'] as int;
  }

  /// Check if there are pending jobs
  Future<bool> hasPendingJobs() async {
    final count = await getJobCount(JobStatus.pending);
    return count > 0;
  }

  /// Generate a unique job ID
  String _generateJobId() {
    return 'job_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Convert Job to database map
  Map<String, dynamic> _jobToMap(Job job) {
    return {
      'id': job.id,
      'type': job.type.name,
      'payload': jsonEncode(job.payload),
      'status': job.status.name,
      'created_at': job.createdAt.millisecondsSinceEpoch,
      'attempts': job.attempts,
      'last_error': job.lastError,
      'scheduled_at': job.scheduledAt?.millisecondsSinceEpoch,
    };
  }

  /// Convert database map to Job
  Job _mapToJob(Map<String, dynamic> map) {
    return Job(
      id: map['id'] as String,
      type: JobType.values.firstWhere((e) => e.name == map['type']),
      payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
      status: JobStatus.values.firstWhere((e) => e.name == map['status']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      attempts: map['attempts'] as int,
      lastError: map['last_error'] as String?,
      scheduledAt: map['scheduled_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduled_at'] as int)
          : null,
    );
  }

  /// Process jobs that are ready for retry with exponential backoff
  Future<void> _processRetryableJobs() async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Get failed jobs that are ready for retry
      final List<Map<String, dynamic>> maps = await db.query(
        'jobs_queue',
        where:
            'status = ? AND attempts < ? AND (scheduled_at IS NULL OR scheduled_at <= ?)',
        whereArgs: [JobStatus.failed.name, 5, now], // Max 5 retry attempts
        orderBy: 'created_at ASC',
      );

      for (final map in maps) {
        final job = _mapToJob(map);

        // Calculate exponential backoff delay
        final backoffDelay = _calculateBackoffDelay(job.attempts);
        final nextRetryTime = DateTime.now().add(backoffDelay);

        // Schedule job for retry
        await db.update(
          'jobs_queue',
          {
            'status': JobStatus.pending.name,
            'scheduled_at': nextRetryTime.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [job.id],
        );

        debugPrint(
          'Scheduled job ${job.id} for retry in ${backoffDelay.inSeconds} seconds',
        );
      }

      // Update status
      await _updateQueueStatus();
    } catch (e) {
      // Don't spam the logs with database errors - just log once and return
      if (e.toString().contains('journal_mode') ||
          e.toString().contains('WAL')) {
        // This is the WAL mode error - we've already handled it in database configuration
        return;
      }
      debugPrint('Error processing retryable jobs: $e');
    }
  }

  /// Calculate exponential backoff delay
  Duration _calculateBackoffDelay(int attempts) {
    // Base delay of 30 seconds, exponentially increased with jitter
    final baseDelay = 30;
    final exponentialDelay = baseDelay * pow(2, attempts).toInt();
    final jitter = Random().nextInt(10); // Add 0-10 seconds jitter
    return Duration(seconds: exponentialDelay + jitter);
  }

  /// Update job queue status and notify listeners
  Future<void> _updateQueueStatus() async {
    final pendingCount = await getJobCount(JobStatus.pending);
    final processingCount = await getJobCount(JobStatus.processing);
    final failedCount = await getJobCount(JobStatus.failed);

    final status = JobQueueStatus(
      pendingJobs: pendingCount,
      processingJobs: processingCount,
      failedJobs: failedCount,
      lastUpdated: DateTime.now(),
    );

    _statusController.add(status);
  }

  /// Schedule background sync for mobile platforms
  Future<void> scheduleBackgroundSync() async {
    // This would integrate with platform-specific background services
    // For Android: WorkManager
    // For iOS: Background App Refresh

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _scheduleAndroidBackgroundSync();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _scheduleIOSBackgroundSync();
    }
  }

  /// Schedule background sync for Android using WorkManager
  Future<void> _scheduleAndroidBackgroundSync() async {
    // This would use a platform channel to schedule WorkManager tasks
    // For now, we'll just log the intent
    debugPrint(
      'Scheduling Android background sync (WorkManager integration needed)',
    );
  }

  /// Schedule background sync for iOS using Background App Refresh
  Future<void> _scheduleIOSBackgroundSync() async {
    // This would use a platform channel to schedule background tasks
    // For now, we'll just log the intent
    debugPrint(
      'Scheduling iOS background sync (Background App Refresh integration needed)',
    );
  }

  /// Get jobs that need conflict resolution
  Future<List<Job>> getConflictedJobs() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'jobs_queue',
      where: 'status = ? AND last_error LIKE ?',
      whereArgs: [JobStatus.failed.name, '%conflict%'],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => _mapToJob(map)).toList();
  }

  /// Resolve a conflicted job by choosing a resolution strategy
  Future<void> resolveConflict(
    String jobId,
    ConflictResolution resolution,
  ) async {
    final db = await _databaseHelper.database;

    switch (resolution) {
      case ConflictResolution.useLocal:
        // Retry the job (use local version)
        await db.update(
          'jobs_queue',
          {
            'status': JobStatus.pending.name,
            'last_error': null,
            'scheduled_at': null,
          },
          where: 'id = ?',
          whereArgs: [jobId],
        );
        break;

      case ConflictResolution.useServer:
        // Mark job as completed (accept server version)
        await completeJob(jobId);
        break;

      case ConflictResolution.merge:
        // For now, treat as use local (merge logic would be entity-specific)
        await db.update(
          'jobs_queue',
          {
            'status': JobStatus.pending.name,
            'last_error': null,
            'scheduled_at': null,
          },
          where: 'id = ?',
          whereArgs: [jobId],
        );
        break;
    }

    await _updateQueueStatus();
  }

  /// Dispose resources
  void dispose() {
    _retryTimer?.cancel();
    _statusController.close();
  }
}

/// Status of the job queue
class JobQueueStatus {
  final int pendingJobs;
  final int processingJobs;
  final int failedJobs;
  final DateTime lastUpdated;

  const JobQueueStatus({
    required this.pendingJobs,
    required this.processingJobs,
    required this.failedJobs,
    required this.lastUpdated,
  });

  bool get hasWork => pendingJobs > 0 || processingJobs > 0;
  bool get hasErrors => failedJobs > 0;
  int get totalJobs => pendingJobs + processingJobs + failedJobs;
}

/// Conflict resolution strategies
enum ConflictResolution {
  useLocal, // Keep local changes
  useServer, // Accept server changes
  merge, // Attempt to merge changes
}
