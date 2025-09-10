/// Sync progress information
class SyncProgress {
  final SyncStatus status;
  final double? progress; // 0.0 to 1.0
  final String? currentOperation;
  final int? totalItems;
  final int? processedItems;
  final DateTime? startedAt;
  final DateTime? lastUpdated;
  final String? error;

  const SyncProgress({
    required this.status,
    this.progress,
    this.currentOperation,
    this.totalItems,
    this.processedItems,
    this.startedAt,
    this.lastUpdated,
    this.error,
  });

  SyncProgress copyWith({
    SyncStatus? status,
    double? progress,
    String? currentOperation,
    int? totalItems,
    int? processedItems,
    DateTime? startedAt,
    DateTime? lastUpdated,
    String? error,
  }) {
    return SyncProgress(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentOperation: currentOperation ?? this.currentOperation,
      totalItems: totalItems ?? this.totalItems,
      processedItems: processedItems ?? this.processedItems,
      startedAt: startedAt ?? this.startedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: error,
    );
  }

  /// Get progress percentage as integer (0-100)
  int get progressPercentage {
    if (progress == null) return 0;
    return (progress! * 100).round().clamp(0, 100);
  }

  /// Check if sync is active
  bool get isActive => status == SyncStatus.syncing;

  /// Check if sync has error
  bool get hasError => status == SyncStatus.error || error != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncProgress &&
        other.status == status &&
        other.progress == progress &&
        other.currentOperation == currentOperation &&
        other.totalItems == totalItems &&
        other.processedItems == processedItems &&
        other.startedAt == startedAt &&
        other.lastUpdated == lastUpdated &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      progress,
      currentOperation,
      totalItems,
      processedItems,
      startedAt,
      lastUpdated,
      error,
    );
  }

  @override
  String toString() {
    return 'SyncProgress(status: $status, progress: $progress, '
           'currentOperation: $currentOperation, error: $error)';
  }
}

/// Sync status enumeration
enum SyncStatus {
  idle,
  syncing,
  completed,
  error,
  paused,
}

/// Job queue status information
class JobQueueStatus {
  final int pendingJobs;
  final int processingJobs;
  final int failedJobs;
  final DateTime? lastUpdated;

  const JobQueueStatus({
    required this.pendingJobs,
    required this.processingJobs,
    required this.failedJobs,
    this.lastUpdated,
  });

  /// Check if there are any errors
  bool get hasErrors => failedJobs > 0;

  /// Check if queue is active
  bool get isActive => processingJobs > 0;

  /// Check if queue is empty
  bool get isEmpty => pendingJobs == 0 && processingJobs == 0 && failedJobs == 0;

  /// Total jobs in queue
  int get totalJobs => pendingJobs + processingJobs + failedJobs;

  JobQueueStatus copyWith({
    int? pendingJobs,
    int? processingJobs,
    int? failedJobs,
    DateTime? lastUpdated,
  }) {
    return JobQueueStatus(
      pendingJobs: pendingJobs ?? this.pendingJobs,
      processingJobs: processingJobs ?? this.processingJobs,
      failedJobs: failedJobs ?? this.failedJobs,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JobQueueStatus &&
        other.pendingJobs == pendingJobs &&
        other.processingJobs == processingJobs &&
        other.failedJobs == failedJobs &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return Object.hash(pendingJobs, processingJobs, failedJobs, lastUpdated);
  }

  @override
  String toString() {
    return 'JobQueueStatus(pending: $pendingJobs, processing: $processingJobs, '
           'failed: $failedJobs, lastUpdated: $lastUpdated)';
  }
}

/// Job type enumeration
enum JobType {
  // Bookmark operations
  createBookmark,
  updateBookmark,
  deleteBookmark,
  
  // Comment operations
  createComment,
  updateComment,
  deleteComment,
  
  // Reading progress operations
  updateReadingProgress,
  deleteReadingProgress,
  
  // Tag operations
  createTag,
  deleteTag,
  addTagToDocument,
  removeTagFromDocument,
  
  // Share operations
  createShare,
  updateShare,
  deleteShare,
  
  // Library operations
  createLibrary,
  deleteLibrary,
  scanLibrary,
}

/// Conflict resolution options
enum ConflictResolution {
  useClient,
  useServer,
  merge,
  skip,
}

/// Job model for queue operations
class Job {
  final String id;
  final JobType type;
  final Map<String, dynamic> payload;
  final JobStatus status;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int attempts;
  final String? error;

  const Job({
    required this.id,
    required this.type,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.attempts = 0,
    this.error,
  });

  Job copyWith({
    String? id,
    JobType? type,
    Map<String, dynamic>? payload,
    JobStatus? status,
    DateTime? createdAt,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? attempts,
    String? error,
  }) {
    return Job(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      attempts: attempts ?? this.attempts,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Job &&
        other.id == id &&
        other.type == type &&
        other.payload == payload &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.scheduledAt == scheduledAt &&
        other.startedAt == startedAt &&
        other.completedAt == completedAt &&
        other.attempts == attempts &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      payload,
      status,
      createdAt,
      scheduledAt,
      startedAt,
      completedAt,
      attempts,
      error,
    );
  }

  @override
  String toString() {
    return 'Job(id: $id, type: $type, status: $status, attempts: $attempts)';
  }
}

/// Job status enumeration
enum JobStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}