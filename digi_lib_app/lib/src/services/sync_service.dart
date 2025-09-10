import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/database_helper.dart';
import '../models/api/sync_models.dart';
import '../models/entities/entities.dart';
import 'sync_api_service.dart';
import 'job_queue_service.dart';
import '../network/connectivity_service.dart';

/// Enum for sync status
enum SyncStatus { idle, syncing, completed, error, offline }

/// Sync progress information
class SyncProgress {
  final SyncStatus status;
  final int totalChanges;
  final int processedChanges;
  final String? message;
  final String? error;

  const SyncProgress({
    required this.status,
    this.totalChanges = 0,
    this.processedChanges = 0,
    this.message,
    this.error,
  });

  double get progress =>
      totalChanges > 0 ? processedChanges / totalChanges : 0.0;

  SyncProgress copyWith({
    SyncStatus? status,
    int? totalChanges,
    int? processedChanges,
    String? message,
    String? error,
  }) {
    return SyncProgress(
      status: status ?? this.status,
      totalChanges: totalChanges ?? this.totalChanges,
      processedChanges: processedChanges ?? this.processedChanges,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }
}

/// Service for handling synchronization between local and remote data
class SyncService {
  final SyncApiService _syncApiService;
  final JobQueueService _jobQueueService;
  final ConnectivityService _connectivityService;
  final DatabaseHelper _databaseHelper;

  final StreamController<SyncProgress> _syncStatusController =
      StreamController<SyncProgress>.broadcast();
  SyncProgress _currentProgress = const SyncProgress(status: SyncStatus.idle);

  Timer? _backgroundSyncTimer;
  bool _isSyncing = false;

  SyncService({
    required SyncApiService syncApiService,
    required JobQueueService jobQueueService,
    required ConnectivityService connectivityService,
    DatabaseHelper? databaseHelper,
  }) : _syncApiService = syncApiService,
       _jobQueueService = jobQueueService,
       _connectivityService = connectivityService,
       _databaseHelper = databaseHelper ?? DatabaseHelper.instance {
    _initializeBackgroundSync();
  }

  /// Stream of sync status updates
  Stream<SyncProgress> get syncStatusStream => _syncStatusController.stream;

  /// Current sync progress
  SyncProgress get currentProgress => _currentProgress;

  /// Check if sync is currently in progress
  bool get isSyncing => _isSyncing;

  /// Initialize background sync scheduling
  void _initializeBackgroundSync() {
    // Schedule periodic sync every 5 minutes when online
    _backgroundSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!_isSyncing && _connectivityService.isConnected) {
        performDeltaSync();
      }
    });

    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen((isConnected) {
      if (isConnected && !_isSyncing) {
        // When coming back online, perform sync
        performDeltaSync();
      } else if (!isConnected) {
        _updateSyncProgress(const SyncProgress(status: SyncStatus.offline));
      }
    });
  }

  /// Perform delta synchronization with the server
  Future<void> performDeltaSync({DateTime? since}) async {
    if (_isSyncing) {
      debugPrint('Sync already in progress, skipping');
      return;
    }

    if (!_connectivityService.isConnected) {
      _updateSyncProgress(
        const SyncProgress(
          status: SyncStatus.offline,
          message: 'No internet connection',
        ),
      );
      return;
    }

    _isSyncing = true;
    _updateSyncProgress(
      const SyncProgress(
        status: SyncStatus.syncing,
        message: 'Starting synchronization...',
      ),
    );

    try {
      // Get last sync timestamp if not provided
      final lastSyncTime = since ?? await _getLastSyncTimestamp();

      debugPrint('Starting delta sync since: $lastSyncTime');

      // Step 1: Get server changes
      _updateSyncProgress(
        _currentProgress.copyWith(message: 'Fetching server changes...'),
      );

      final manifest = await _syncApiService.getSyncManifest(
        since: lastSyncTime,
      );

      debugPrint('Received ${manifest.changes.length} changes from server');

      // Step 2: Apply server changes locally
      if (manifest.changes.isNotEmpty) {
        await _applyServerChanges(manifest.changes);
      }

      // Step 3: Push local changes
      await pushOfflineActions();

      // Step 4: Update last sync timestamp
      await _updateLastSyncTimestamp(manifest.timestamp);

      _updateSyncProgress(
        SyncProgress(
          status: SyncStatus.completed,
          totalChanges: manifest.changes.length,
          processedChanges: manifest.changes.length,
          message: 'Synchronization completed successfully',
        ),
      );

      debugPrint('Delta sync completed successfully');
    } catch (e, stackTrace) {
      debugPrint('Sync error: $e');
      debugPrint('Stack trace: $stackTrace');

      _updateSyncProgress(
        SyncProgress(
          status: SyncStatus.error,
          error: e.toString(),
          message: 'Synchronization failed',
        ),
      );
    } finally {
      _isSyncing = false;

      // Reset to idle after a delay
      Timer(const Duration(seconds: 3), () {
        if (_currentProgress.status != SyncStatus.syncing) {
          _updateSyncProgress(const SyncProgress(status: SyncStatus.idle));
        }
      });
    }
  }

  /// Push offline actions to the server
  Future<void> pushOfflineActions() async {
    if (!_connectivityService.isConnected) {
      debugPrint('Cannot push offline actions: no internet connection');
      return;
    }

    _updateSyncProgress(
      _currentProgress.copyWith(message: 'Pushing local changes...'),
    );

    // Get pending jobs from queue
    final pendingJobs = await _jobQueueService.getPendingJobs();
    if (pendingJobs.isEmpty) {
      debugPrint('No pending jobs to sync');
      return;
    }

    debugPrint('Pushing ${pendingJobs.length} offline actions');

    // Convert jobs to sync changes
    final changes = <SyncChange>[];
    for (final job in pendingJobs) {
      final syncChange = _jobToSyncChange(job);
      if (syncChange != null) {
        changes.add(syncChange);
      }
    }

    if (changes.isEmpty) {
      debugPrint('No valid sync changes to push');
      return;
    }

    try {
      final request = SyncPushRequest(
        changes: changes,
        clientTimestamp: DateTime.now(),
      );

      final response = await _syncApiService.pushLocalChanges(request);

      debugPrint(
        'Push response: ${response.acceptedChanges.length} accepted, ${response.conflicts.length} conflicts',
      );

      // Handle accepted changes - remove from job queue
      for (final changeId in response.acceptedChanges) {
        final job = pendingJobs.firstWhere(
          (j) => j.id == changeId,
          orElse: () =>
              throw StateError('Job not found for change ID: $changeId'),
        );
        await _jobQueueService.completeJob(job.id);
      }

      // Handle conflicts
      if (response.conflicts.isNotEmpty) {
        await _handleSyncConflicts(response.conflicts, pendingJobs);
      }
    } catch (e) {
      debugPrint('Failed to push offline actions: $e');

      // Mark jobs as failed with retry
      for (final job in pendingJobs) {
        await _jobQueueService.incrementJobAttempts(
          job.id,
          error: e.toString(),
        );

        // If too many attempts, mark as failed
        if (job.attempts >= 3) {
          await _jobQueueService.failJob(
            job.id,
            'Max retry attempts exceeded: $e',
          );
        }
      }

      rethrow;
    }
  }

  /// Apply server changes to local database
  Future<void> _applyServerChanges(List<SyncChange> changes) async {
    _updateSyncProgress(
      _currentProgress.copyWith(
        totalChanges: changes.length,
        processedChanges: 0,
        message: 'Applying server changes...',
      ),
    );

    final db = await _databaseHelper.database;

    for (int i = 0; i < changes.length; i++) {
      final change = changes[i];

      try {
        await _applySyncChange(db, change);

        _updateSyncProgress(_currentProgress.copyWith(processedChanges: i + 1));
      } catch (e) {
        debugPrint('Failed to apply sync change ${change.entityId}: $e');
        // Continue with other changes
      }
    }
  }

  /// Apply a single sync change to the local database
  Future<void> _applySyncChange(Database db, SyncChange change) async {
    switch (change.entityType) {
      case 'document':
        await _applyDocumentChange(db, change);
        break;
      case 'bookmark':
        await _applyBookmarkChange(db, change);
        break;
      case 'comment':
        await _applyCommentChange(db, change);
        break;
      case 'reading_progress':
        await _applyReadingProgressChange(db, change);
        break;
      case 'tag':
        await _applyTagChange(db, change);
        break;
      case 'document_tag':
        await _applyDocumentTagChange(db, change);
        break;
      case 'share':
        await _applyShareChange(db, change);
        break;
      default:
        debugPrint('Unknown entity type: ${change.entityType}');
    }
  }

  /// Apply document changes
  Future<void> _applyDocumentChange(Database db, SyncChange change) async {
    switch (change.operation) {
      case 'create':
      case 'update':
        if (change.data != null) {
          final document = Document.fromJson(change.data!);
          await db.insert(
            'documents',
            document.toJson()
              ..['synced_at'] = DateTime.now().millisecondsSinceEpoch,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        break;
      case 'delete':
        await db.delete(
          'documents',
          where: 'id = ?',
          whereArgs: [change.entityId],
        );
        break;
    }
  }

  /// Apply bookmark changes
  Future<void> _applyBookmarkChange(Database db, SyncChange change) async {
    switch (change.operation) {
      case 'create':
      case 'update':
        if (change.data != null) {
          final bookmark = Bookmark.fromJson(change.data!);
          await db.insert(
            'bookmarks',
            bookmark.toJson()..['synced'] = 1,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        break;
      case 'delete':
        await db.delete(
          'bookmarks',
          where: 'id = ?',
          whereArgs: [change.entityId],
        );
        break;
    }
  }

  /// Apply comment changes
  Future<void> _applyCommentChange(Database db, SyncChange change) async {
    switch (change.operation) {
      case 'create':
      case 'update':
        if (change.data != null) {
          final comment = Comment.fromJson(change.data!);
          await db.insert(
            'comments',
            comment.toJson()..['synced'] = 1,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        break;
      case 'delete':
        await db.delete(
          'comments',
          where: 'id = ?',
          whereArgs: [change.entityId],
        );
        break;
    }
  }

  /// Apply reading progress changes
  Future<void> _applyReadingProgressChange(
    Database db,
    SyncChange change,
  ) async {
    switch (change.operation) {
      case 'create':
      case 'update':
        if (change.data != null) {
          final progress = ReadingProgress.fromJson(change.data!);
          await db.insert(
            'reading_progress',
            progress.toJson()..['synced'] = 1,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        break;
      case 'delete':
        await db.delete(
          'reading_progress',
          where: 'user_id = ? AND doc_id = ?',
          whereArgs: [change.data?['user_id'], change.data?['doc_id']],
        );
        break;
    }
  }

  /// Apply tag changes
  Future<void> _applyTagChange(Database db, SyncChange change) async {
    switch (change.operation) {
      case 'create':
      case 'update':
        if (change.data != null) {
          final tag = Tag.fromJson(change.data!);
          await db.insert(
            'tags',
            tag.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        break;
      case 'delete':
        await db.delete('tags', where: 'id = ?', whereArgs: [change.entityId]);
        break;
    }
  }

  /// Apply document tag changes
  Future<void> _applyDocumentTagChange(Database db, SyncChange change) async {
    switch (change.operation) {
      case 'create':
        if (change.data != null) {
          await db.insert(
            'document_tags',
            change.data!,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        break;
      case 'delete':
        await db.delete(
          'document_tags',
          where: 'id = ?',
          whereArgs: [change.entityId],
        );
        break;
    }
  }

  /// Apply share changes
  Future<void> _applyShareChange(Database db, SyncChange change) async {
    switch (change.operation) {
      case 'create':
      case 'update':
        if (change.data != null) {
          final share = Share.fromJson(change.data!);
          await db.insert(
            'shares',
            share.toJson()..['synced'] = 1,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        break;
      case 'delete':
        await db.delete(
          'shares',
          where: 'id = ?',
          whereArgs: [change.entityId],
        );
        break;
    }
  }

  /// Convert job to sync change
  SyncChange? _jobToSyncChange(Job job) {
    final entityType = _getEntityTypeFromJobType(job.type);
    if (entityType == null) return null;

    final operation = _getOperationFromJobType(job.type);
    if (operation == null) return null;

    return SyncChange(
      entityType: entityType,
      entityId: job.payload['id'] ?? job.payload['entity_id'] ?? job.id,
      operation: operation,
      data: job.payload,
      timestamp: job.createdAt,
    );
  }

  /// Get entity type from job type
  String? _getEntityTypeFromJobType(JobType jobType) {
    switch (jobType) {
      case JobType.createBookmark:
      case JobType.updateBookmark:
      case JobType.deleteBookmark:
        return 'bookmark';
      case JobType.createComment:
      case JobType.updateComment:
      case JobType.deleteComment:
        return 'comment';
      case JobType.updateReadingProgress:
      case JobType.deleteReadingProgress:
        return 'reading_progress';
      case JobType.createTag:
      case JobType.deleteTag:
        return 'tag';
      case JobType.addTagToDocument:
      case JobType.removeTagFromDocument:
        return 'document_tag';
      case JobType.createShare:
      case JobType.updateShare:
      case JobType.deleteShare:
        return 'share';
      case JobType.createLibrary:
      case JobType.deleteLibrary:
      case JobType.scanLibrary:
        return 'library';
    }
  }

  /// Get operation from job type
  String? _getOperationFromJobType(JobType jobType) {
    switch (jobType) {
      case JobType.createBookmark:
      case JobType.createComment:
      case JobType.createTag:
      case JobType.addTagToDocument:
      case JobType.createShare:
        return 'create';
      case JobType.updateBookmark:
      case JobType.updateComment:
      case JobType.updateReadingProgress:
      case JobType.updateShare:
        return 'update';
      case JobType.deleteBookmark:
      case JobType.deleteComment:
      case JobType.deleteReadingProgress:
      case JobType.deleteTag:
      case JobType.removeTagFromDocument:
      case JobType.deleteShare:
      case JobType.deleteLibrary:
        return 'delete';
      case JobType.createLibrary:
        return 'create';
      case JobType.scanLibrary:
        return 'scan';
    }
  }

  /// Handle sync conflicts using last-write-wins strategy
  Future<void> _handleSyncConflicts(
    List<SyncConflict> conflicts,
    List<Job> pendingJobs,
  ) async {
    debugPrint('Handling ${conflicts.length} sync conflicts');

    for (final conflict in conflicts) {
      debugPrint(
        'Conflict for ${conflict.entityType}:${conflict.entityId} - ${conflict.resolution}',
      );

      switch (conflict.resolution) {
        case 'server_wins':
          // Apply server version and remove local job
          final job = pendingJobs.firstWhere(
            (j) =>
                j.payload['id'] == conflict.entityId ||
                j.payload['entity_id'] == conflict.entityId,
            orElse: () => throw StateError(
              'Job not found for conflict entity: ${conflict.entityId}',
            ),
          );

          // Apply server version
          final serverChange = SyncChange(
            entityType: conflict.entityType,
            entityId: conflict.entityId,
            operation: 'update',
            data: conflict.serverVersion,
            timestamp: DateTime.now(),
          );

          final db = await _databaseHelper.database;
          await _applySyncChange(db, serverChange);

          // Remove local job
          await _jobQueueService.completeJob(job.id);
          break;

        case 'client_wins':
          // Keep local version, server will accept it
          final job = pendingJobs.firstWhere(
            (j) =>
                j.payload['id'] == conflict.entityId ||
                j.payload['entity_id'] == conflict.entityId,
            orElse: () => throw StateError(
              'Job not found for conflict entity: ${conflict.entityId}',
            ),
          );
          await _jobQueueService.completeJob(job.id);
          break;

        case 'merge_required':
          // For now, use server_wins strategy
          // TODO: Implement proper merge logic for specific entity types
          debugPrint(
            'Merge required for ${conflict.entityType}:${conflict.entityId}, using server_wins',
          );

          final job = pendingJobs.firstWhere(
            (j) =>
                j.payload['id'] == conflict.entityId ||
                j.payload['entity_id'] == conflict.entityId,
            orElse: () => throw StateError(
              'Job not found for conflict entity: ${conflict.entityId}',
            ),
          );

          final serverChange = SyncChange(
            entityType: conflict.entityType,
            entityId: conflict.entityId,
            operation: 'update',
            data: conflict.serverVersion,
            timestamp: DateTime.now(),
          );

          final db = await _databaseHelper.database;
          await _applySyncChange(db, serverChange);
          await _jobQueueService.completeJob(job.id);
          break;
      }
    }
  }

  /// Get last sync timestamp from local storage
  Future<DateTime?> _getLastSyncTimestamp() async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: ['last_sync_timestamp'],
      limit: 1,
    );

    if (result.isNotEmpty) {
      final timestamp = result.first['value'] as String;
      return DateTime.parse(timestamp);
    }

    return null;
  }

  /// Update last sync timestamp in local storage
  Future<void> _updateLastSyncTimestamp(DateTime timestamp) async {
    final db = await _databaseHelper.database;
    await db.insert('sync_metadata', {
      'key': 'last_sync_timestamp',
      'value': timestamp.toIso8601String(),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Update sync progress and notify listeners
  void _updateSyncProgress(SyncProgress progress) {
    _currentProgress = progress;
    _syncStatusController.add(progress);
  }

  /// Schedule background sync for mobile platforms
  Future<void> scheduleBackgroundSync() async {
    // This would integrate with platform-specific background services
    // For now, we rely on the periodic timer when app is active
    debugPrint(
      'Background sync scheduling not implemented for current platform',
    );
  }

  /// Force sync now (useful for manual sync triggers)
  Future<void> forceSyncNow() async {
    await performDeltaSync();
  }

  /// Dispose resources
  void dispose() {
    _backgroundSyncTimer?.cancel();
    _syncStatusController.close();
  }
}
