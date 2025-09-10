import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync_service.dart';
import '../services/job_queue_service.dart' as job_queue;
import '../network/connectivity_service.dart';
import '../models/api/sync_models.dart';
import '../models/ui/sync_status_models.dart' as ui;
import 'library_provider.dart';

/// Provider for sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  throw UnimplementedError('SyncService must be overridden');
});

// JobQueueService provider is imported from library_provider.dart

/// Provider for connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

/// Provider for current sync progress
final syncProgressProvider = StreamProvider<ui.SyncProgress>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.syncStatusStream.map((serviceProgress) {
    return ui.SyncProgress(
      status: _mapSyncStatus(serviceProgress.status),
      progress: serviceProgress.progress,
      currentOperation: serviceProgress.message,
      totalItems: serviceProgress.totalChanges,
      processedItems: serviceProgress.processedChanges,
      lastUpdated: DateTime.now(),
      error: serviceProgress.error,
    );
  });
});

/// Provider for connectivity status
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.connectivityStream;
});

/// Provider for job queue status
final jobQueueStatusProvider = StreamProvider<ui.JobQueueStatus>((ref) {
  final jobQueueService = ref.watch(jobQueueServiceProvider);
  return jobQueueService.statusStream.map((serviceStatus) {
    return ui.JobQueueStatus(
      pendingJobs: serviceStatus.pendingJobs,
      processingJobs: serviceStatus.processingJobs,
      failedJobs: serviceStatus.failedJobs,
      lastUpdated: serviceStatus.lastUpdated,
    );
  });
});

/// Provider for sync conflicts
final syncConflictsProvider = FutureProvider<List<SyncConflict>>((ref) async {
  final jobQueueService = ref.watch(jobQueueServiceProvider);

  // Get jobs that have conflict errors
  final conflictedJobs = await jobQueueService.getConflictedJobs();

  // Convert jobs to sync conflicts (simplified)
  return conflictedJobs.map((job) {
    return SyncConflict(
      entityId: job.payload['id'] ?? job.id,
      entityType: _getEntityTypeFromJobType(_convertJobType(job.type)),
      clientVersion: job.payload,
      serverVersion: {}, // Would need to fetch from server
      resolution: 'merge_required',
    );
  }).toList();
});

/// Combined sync status provider that aggregates all sync-related information
final combinedSyncStatusProvider = Provider<CombinedSyncStatus>((ref) {
  final syncProgress = ref.watch(syncProgressProvider);
  final connectivity = ref.watch(connectivityProvider);
  final jobQueueStatus = ref.watch(jobQueueStatusProvider);
  final conflicts = ref.watch(syncConflictsProvider);

  return CombinedSyncStatus(
    syncProgress: syncProgress.when(
      data: (progress) => progress,
      loading: () => const ui.SyncProgress(status: ui.SyncStatus.idle),
      error: (_, __) => const ui.SyncProgress(
        status: ui.SyncStatus.error,
        error: 'Failed to get sync status',
      ),
    ),
    isOnline: connectivity.when(
      data: (isConnected) => isConnected,
      loading: () => true,
      error: (_, __) => false,
    ),
    jobQueueStatus: jobQueueStatus.when(
      data: (status) => status,
      loading: () => ui.JobQueueStatus(
        pendingJobs: 0,
        processingJobs: 0,
        failedJobs: 0,
        lastUpdated: DateTime.now(),
      ),
      error: (_, __) => ui.JobQueueStatus(
        pendingJobs: 0,
        processingJobs: 0,
        failedJobs: 0,
        lastUpdated: DateTime.now(),
      ),
    ),
    conflicts: conflicts.when(
      data: (conflictList) => conflictList,
      loading: () => <SyncConflict>[],
      error: (_, __) => <SyncConflict>[],
    ),
  );
});

/// Notifier for sync actions
class SyncActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final SyncService _syncService;
  final job_queue.JobQueueService _jobQueueService;

  SyncActionsNotifier(this._syncService, this._jobQueueService)
    : super(const AsyncValue.data(null));

  /// Force sync now
  Future<void> forceSyncNow() async {
    state = const AsyncValue.loading();
    try {
      await _syncService.forceSyncNow();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Retry failed jobs
  Future<void> retryFailedJobs() async {
    state = const AsyncValue.loading();
    try {
      await _jobQueueService.retryFailedJobs();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Resolve sync conflict
  Future<void> resolveConflict(
    String jobId,
    ui.ConflictResolution resolution,
  ) async {
    try {
      await _jobQueueService.resolveConflict(
        jobId,
        _convertConflictResolution(resolution),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Clear old completed jobs
  Future<void> clearOldJobs() async {
    try {
      await _jobQueueService.clearOldJobs();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for sync actions
final syncActionsProvider =
    StateNotifierProvider<SyncActionsNotifier, AsyncValue<void>>((ref) {
      final syncService = ref.watch(syncServiceProvider);
      final jobQueueService = ref.watch(jobQueueServiceProvider);
      return SyncActionsNotifier(syncService, jobQueueService);
    });

/// Combined sync status model
class CombinedSyncStatus {
  final ui.SyncProgress syncProgress;
  final bool isOnline;
  final ui.JobQueueStatus jobQueueStatus;
  final List<SyncConflict> conflicts;

  const CombinedSyncStatus({
    required this.syncProgress,
    required this.isOnline,
    required this.jobQueueStatus,
    required this.conflicts,
  });

  /// Whether sync is currently active
  bool get isSyncing => syncProgress.status == ui.SyncStatus.syncing;

  /// Whether there are any issues that need attention
  bool get hasIssues =>
      syncProgress.status == ui.SyncStatus.error ||
      jobQueueStatus.hasErrors ||
      conflicts.isNotEmpty;

  /// Whether the app is in offline mode
  bool get isOffline => !isOnline;

  /// Number of pending actions
  int get pendingActions => jobQueueStatus.pendingJobs;

  /// Number of failed actions
  int get failedActions => jobQueueStatus.failedJobs;

  /// Whether there are conflicts to resolve
  bool get hasConflicts => conflicts.isNotEmpty;

  /// Overall sync health status
  SyncHealthStatus get healthStatus {
    if (hasConflicts) return SyncHealthStatus.conflicts;
    if (syncProgress.status == ui.SyncStatus.error) {
      return SyncHealthStatus.error;
    }
    if (jobQueueStatus.hasErrors) return SyncHealthStatus.error;
    if (isOffline && pendingActions > 0) return SyncHealthStatus.offline;
    if (isSyncing) return SyncHealthStatus.syncing;
    return SyncHealthStatus.healthy;
  }

  CombinedSyncStatus copyWith({
    ui.SyncProgress? syncProgress,
    bool? isOnline,
    ui.JobQueueStatus? jobQueueStatus,
    List<SyncConflict>? conflicts,
  }) {
    return CombinedSyncStatus(
      syncProgress: syncProgress ?? this.syncProgress,
      isOnline: isOnline ?? this.isOnline,
      jobQueueStatus: jobQueueStatus ?? this.jobQueueStatus,
      conflicts: conflicts ?? this.conflicts,
    );
  }
}

/// Enum for overall sync health status
enum SyncHealthStatus { healthy, syncing, offline, error, conflicts }

/// Helper function to get entity type from job type
String _getEntityTypeFromJobType(ui.JobType jobType) {
  switch (jobType) {
    case ui.JobType.createBookmark:
    case ui.JobType.updateBookmark:
    case ui.JobType.deleteBookmark:
      return 'bookmark';
    case ui.JobType.createComment:
    case ui.JobType.updateComment:
    case ui.JobType.deleteComment:
      return 'comment';
    case ui.JobType.updateReadingProgress:
    case ui.JobType.deleteReadingProgress:
      return 'reading_progress';
    case ui.JobType.createTag:
    case ui.JobType.deleteTag:
      return 'tag';
    case ui.JobType.addTagToDocument:
    case ui.JobType.removeTagFromDocument:
      return 'document_tag';
    case ui.JobType.createShare:
    case ui.JobType.updateShare:
    case ui.JobType.deleteShare:
      return 'share';
    case ui.JobType.createLibrary:
    case ui.JobType.deleteLibrary:
    case ui.JobType.scanLibrary:
      return 'library';
  }
}

/// Helper function to map service SyncStatus to UI SyncStatus
ui.SyncStatus _mapSyncStatus(SyncStatus serviceStatus) {
  switch (serviceStatus) {
    case SyncStatus.idle:
      return ui.SyncStatus.idle;
    case SyncStatus.syncing:
      return ui.SyncStatus.syncing;
    case SyncStatus.completed:
      return ui.SyncStatus.completed;
    case SyncStatus.error:
      return ui.SyncStatus.error;
    case SyncStatus.offline:
      return ui.SyncStatus.paused; // Map offline to paused in UI
  }
}

/// Convert job queue JobType to ui JobType
ui.JobType _convertJobType(job_queue.JobType jobType) {
  switch (jobType) {
    case job_queue.JobType.createBookmark:
      return ui.JobType.createBookmark;
    case job_queue.JobType.updateBookmark:
      return ui.JobType.updateBookmark;
    case job_queue.JobType.deleteBookmark:
      return ui.JobType.deleteBookmark;
    case job_queue.JobType.createComment:
      return ui.JobType.createComment;
    case job_queue.JobType.updateComment:
      return ui.JobType.updateComment;
    case job_queue.JobType.deleteComment:
      return ui.JobType.deleteComment;
    case job_queue.JobType.updateReadingProgress:
      return ui.JobType.updateReadingProgress;
    case job_queue.JobType.deleteReadingProgress:
      return ui.JobType.deleteReadingProgress;
    case job_queue.JobType.createTag:
      return ui.JobType.createTag;
    case job_queue.JobType.deleteTag:
      return ui.JobType.deleteTag;
    case job_queue.JobType.addTagToDocument:
      return ui.JobType.addTagToDocument;
    case job_queue.JobType.removeTagFromDocument:
      return ui.JobType.removeTagFromDocument;
    default:
      return ui.JobType.createBookmark; // fallback
  }
}

/// Convert ui ConflictResolution to service ConflictResolution
job_queue.ConflictResolution _convertConflictResolution(
  ui.ConflictResolution resolution,
) {
  switch (resolution) {
    case ui.ConflictResolution.useClient:
      return job_queue.ConflictResolution.useLocal;
    case ui.ConflictResolution.useServer:
      return job_queue.ConflictResolution.useServer;
    case ui.ConflictResolution.merge:
      return job_queue.ConflictResolution.merge;
    case ui.ConflictResolution.skip:
      return job_queue.ConflictResolution.useLocal; // fallback for skip
  }
}
