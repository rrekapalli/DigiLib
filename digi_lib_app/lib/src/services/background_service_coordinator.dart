import 'dart:async';
import 'package:flutter/foundation.dart';

import 'background_task_service.dart';
import 'notification_service.dart';
import 'job_queue_service.dart';
import 'sync_service.dart';
import '../network/connectivity_service.dart';

/// Coordinator service that integrates background tasks, notifications, and job processing
class BackgroundServiceCoordinator {
  final BackgroundTaskService _backgroundTaskService;
  final NotificationService _notificationService;
  final JobQueueService _jobQueueService;
  final SyncService _syncService;
  final ConnectivityService _connectivityService;
  
  late StreamSubscription _taskResultSubscription;
  late StreamSubscription _jobQueueSubscription;
  late StreamSubscription _syncStatusSubscription;
  
  bool _isInitialized = false;

  BackgroundServiceCoordinator({
    required BackgroundTaskService backgroundTaskService,
    required NotificationService notificationService,
    required JobQueueService jobQueueService,
    required SyncService syncService,
    required ConnectivityService connectivityService,
  }) : _backgroundTaskService = backgroundTaskService,
       _notificationService = notificationService,
       _jobQueueService = jobQueueService,
       _syncService = syncService,
       _connectivityService = connectivityService;

  /// Initialize the coordinator and all services
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('BackgroundServiceCoordinator already initialized');
      return;
    }

    debugPrint('Initializing BackgroundServiceCoordinator');

    try {
      // Initialize all services
      await _connectivityService.initialize();
      await _notificationService.initialize();
      await _backgroundTaskService.initialize();
      
      // Set up event listeners
      _setupEventListeners();
      
      // Schedule initial background tasks
      await _scheduleInitialTasks();
      
      _isInitialized = true;
      debugPrint('BackgroundServiceCoordinator initialized successfully');
      
    } catch (e) {
      debugPrint('Failed to initialize BackgroundServiceCoordinator: $e');
      rethrow;
    }
  }

  /// Set up event listeners between services
  void _setupEventListeners() {
    // Listen to background task results and send notifications
    _taskResultSubscription = _backgroundTaskService.taskResultStream.listen((result) {
      _handleTaskResult(result);
    });

    // Listen to job queue status changes
    _jobQueueSubscription = _jobQueueService.statusStream.listen((status) {
      _handleJobQueueStatusChange(status);
    });

    // Listen to sync status changes (if available)
    // _syncStatusSubscription = _syncService.syncStatusStream.listen((status) {
    //   _handleSyncStatusChange(status);
    // });
  }

  /// Handle background task results
  Future<void> _handleTaskResult(TaskResult result) async {
    debugPrint('Handling task result: ${result.taskId} - ${result.success ? 'success' : 'failed'}');

    if (result.success) {
      // Send success notification based on task type
      switch (result.taskId.split('_')[0]) {
        case 'sync':
          final itemsSynced = result.data?['synced_items'] as int? ?? 0;
          await _notificationService.sendSyncCompletedNotification(itemsSynced);
          break;
        case 'cache':
          final cleanedBytes = result.data?['cleaned_bytes'] as int? ?? 0;
          await _notificationService.sendBackgroundTaskCompletedNotification(
            'Cache Cleanup',
            {'cleaned_bytes': cleanedBytes},
          );
          break;
        default:
          await _notificationService.sendBackgroundTaskCompletedNotification(
            result.taskId.split('_')[0],
            result.data,
          );
      }
    } else {
      // Send failure notification
      await _notificationService.sendBackgroundTaskFailedNotification(
        result.taskId.split('_')[0],
        result.error ?? 'Unknown error',
      );
    }
  }

  /// Handle job queue status changes
  Future<void> _handleJobQueueStatusChange(JobQueueStatus status) async {
    debugPrint('Job queue status changed: ${status.pendingJobs} pending, ${status.failedJobs} failed');

    // If there are pending jobs and we're connected, schedule a sync task
    if (status.pendingJobs > 0 && _connectivityService.isConnected) {
      await _scheduleHighPrioritySyncTask();
    }

    // If there are failed jobs, consider showing a notification
    if (status.failedJobs > 0) {
      await _notificationService.sendJobFailedNotification(
        'Multiple Jobs',
        '${status.failedJobs} jobs failed and need attention',
      );
    }
  }

  /// Schedule initial background tasks
  Future<void> _scheduleInitialTasks() async {
    // Schedule periodic sync
    await _backgroundTaskService.schedulePeriodicSync();
    
    // Schedule cache cleanup
    await _backgroundTaskService.scheduleCacheCleanup();
    
    debugPrint('Initial background tasks scheduled');
  }

  /// Schedule high priority sync task
  Future<void> _scheduleHighPrioritySyncTask() async {
    final syncTask = BackgroundTask(
      id: 'urgent_sync_${DateTime.now().millisecondsSinceEpoch}',
      type: BackgroundTaskType.sync,
      priority: TaskPriority.high,
      payload: {'trigger': 'pending_jobs'},
      scheduledAt: DateTime.now(),
      requiresNetwork: true,
    );
    
    await _backgroundTaskService.scheduleTask(syncTask);
  }

  /// Schedule document processing task
  Future<void> scheduleDocumentProcessing(String documentId, Map<String, dynamic> options) async {
    final task = BackgroundTask(
      id: 'doc_process_${documentId}_${DateTime.now().millisecondsSinceEpoch}',
      type: BackgroundTaskType.documentProcessing,
      priority: TaskPriority.normal,
      payload: {
        'document_id': documentId,
        'options': options,
      },
      scheduledAt: DateTime.now(),
      requiresNetwork: false,
    );
    
    await _backgroundTaskService.scheduleTask(task);
  }

  /// Schedule indexing task
  Future<void> scheduleIndexing(List<String> documentIds) async {
    final task = BackgroundTask(
      id: 'indexing_${DateTime.now().millisecondsSinceEpoch}',
      type: BackgroundTaskType.indexing,
      priority: TaskPriority.low,
      payload: {
        'document_ids': documentIds,
      },
      scheduledAt: DateTime.now(),
      requiresNetwork: false,
    );
    
    await _backgroundTaskService.scheduleTask(task);
  }

  /// Show scan progress notification
  Future<void> showScanProgress(String libraryName, int progress, int total) async {
    await _notificationService.showProgressNotification(
      id: 'scan_$libraryName',
      title: 'Scanning Library',
      message: 'Scanning "$libraryName"',
      progress: progress,
      maxProgress: total,
    );
  }

  /// Update scan progress notification
  Future<void> updateScanProgress(String libraryName, int progress, int total) async {
    await _notificationService.updateProgressNotification(
      id: 'scan_$libraryName',
      title: 'Scanning Library',
      message: 'Scanning "$libraryName": $progress of $total',
      progress: progress,
      maxProgress: total,
    );
  }

  /// Complete scan and show final notification
  Future<void> completeScan(String libraryName, int documentsFound) async {
    // Cancel progress notification
    await _notificationService.cancelNotification('scan_$libraryName');
    
    // Show completion notification
    await _notificationService.sendScanCompletedNotification(libraryName, documentsFound);
  }

  /// Get coordinator statistics
  Map<String, dynamic> getStatistics() {
    return {
      'is_initialized': _isInitialized,
      'background_tasks': _backgroundTaskService.getStatistics(),
      'notifications': _notificationService.getStatistics(),
      'connectivity': {
        'is_connected': _connectivityService.isConnected,
      },
    };
  }

  /// Check if all services are healthy
  bool get isHealthy {
    return _isInitialized &&
           _backgroundTaskService.isRunning &&
           _notificationService.isInitialized;
  }

  /// Dispose all resources
  Future<void> dispose() async {
    debugPrint('Disposing BackgroundServiceCoordinator');
    
    _isInitialized = false;
    
    // Cancel subscriptions
    await _taskResultSubscription.cancel();
    await _jobQueueSubscription.cancel();
    // await _syncStatusSubscription.cancel();
    
    // Dispose services
    await _backgroundTaskService.dispose();
    await _notificationService.dispose();
    _connectivityService.dispose();
    
    debugPrint('BackgroundServiceCoordinator disposed');
  }
}