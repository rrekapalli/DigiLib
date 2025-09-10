import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'job_queue_service.dart';
import '../network/connectivity_service.dart';

/// Priority levels for background tasks
enum TaskPriority {
  low(0),
  normal(1),
  high(2),
  critical(3);

  const TaskPriority(this.value);
  final int value;
}

/// Types of background tasks
enum BackgroundTaskType {
  sync,
  documentProcessing,
  cacheCleanup,
  indexing,
  notification,
}

/// Background task definition
class BackgroundTask {
  final String id;
  final BackgroundTaskType type;
  final TaskPriority priority;
  final Map<String, dynamic> payload;
  final DateTime scheduledAt;
  final Duration? timeout;
  final int maxRetries;
  final bool requiresNetwork;

  const BackgroundTask({
    required this.id,
    required this.type,
    required this.priority,
    required this.payload,
    required this.scheduledAt,
    this.timeout,
    this.maxRetries = 3,
    this.requiresNetwork = true,
  });

  BackgroundTask copyWith({
    String? id,
    BackgroundTaskType? type,
    TaskPriority? priority,
    Map<String, dynamic>? payload,
    DateTime? scheduledAt,
    Duration? timeout,
    int? maxRetries,
    bool? requiresNetwork,
  }) {
    return BackgroundTask(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      payload: payload ?? this.payload,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      timeout: timeout ?? this.timeout,
      maxRetries: maxRetries ?? this.maxRetries,
      requiresNetwork: requiresNetwork ?? this.requiresNetwork,
    );
  }
}

/// Background task execution result
class TaskResult {
  final String taskId;
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;
  final Duration executionTime;

  const TaskResult({
    required this.taskId,
    required this.success,
    this.error,
    this.data,
    required this.executionTime,
  });
}

/// Background task status
enum TaskStatus { pending, running, completed, failed, cancelled }

/// Service for orchestrating background tasks with isolate management
class BackgroundTaskService {
  static const MethodChannel _channel = MethodChannel(
    'digi_lib_app/background_tasks',
  );

  final JobQueueService _jobQueueService;
  final ConnectivityService _connectivityService;

  final Map<String, BackgroundTask> _pendingTasks = {};
  final Map<String, TaskStatus> _taskStatuses = {};
  final Map<String, Isolate> _runningIsolates = {};
  final Map<String, ReceivePort> _isolateReceivePorts = {};

  Timer? _taskScheduler;
  Timer? _cleanupTimer;
  bool _isServiceRunning = false;

  final StreamController<TaskResult> _taskResultController =
      StreamController<TaskResult>.broadcast();
  final StreamController<Map<String, TaskStatus>> _taskStatusController =
      StreamController<Map<String, TaskStatus>>.broadcast();

  BackgroundTaskService({
    required JobQueueService jobQueueService,
    required ConnectivityService connectivityService,
  }) : _jobQueueService = jobQueueService,
       _connectivityService = connectivityService;

  /// Stream of task results
  Stream<TaskResult> get taskResultStream => _taskResultController.stream;

  /// Stream of task status updates
  Stream<Map<String, TaskStatus>> get taskStatusStream =>
      _taskStatusController.stream;

  /// Check if service is running
  bool get isRunning => _isServiceRunning;

  /// Get current task statuses
  Map<String, TaskStatus> get taskStatuses => Map.unmodifiable(_taskStatuses);

  /// Initialize the background task service
  Future<void> initialize() async {
    if (_isServiceRunning) {
      debugPrint('BackgroundTaskService already running');
      return;
    }

    debugPrint('Initializing BackgroundTaskService');

    try {
      // Initialize platform-specific background services
      await _initializePlatformServices();

      // Start task scheduler
      _startTaskScheduler();

      // Start cleanup timer
      _startCleanupTimer();

      // Listen to connectivity changes
      _connectivityService.connectivityStream.listen(_onConnectivityChanged);

      // Listen to job queue changes
      _jobQueueService.statusStream.listen(_onJobQueueStatusChanged);

      _isServiceRunning = true;
      debugPrint('BackgroundTaskService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize BackgroundTaskService: $e');
      rethrow;
    }
  }

  /// Initialize platform-specific background services
  Future<void> _initializePlatformServices() async {
    if (kIsWeb) {
      debugPrint('Background tasks not fully supported on web platform');
      return;
    }

    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('initializeAndroidBackgroundService');
      } else if (Platform.isIOS) {
        await _channel.invokeMethod('initializeIOSBackgroundService');
      }
    } catch (e) {
      debugPrint('Platform-specific initialization failed: $e');
      // Continue with basic functionality
    }
  }

  /// Schedule a background task
  Future<void> scheduleTask(BackgroundTask task) async {
    debugPrint('Scheduling background task: ${task.id} (${task.type.name})');

    _pendingTasks[task.id] = task;
    _taskStatuses[task.id] = TaskStatus.pending;

    _notifyStatusChange();

    // If task should run immediately and conditions are met, execute it
    if (task.scheduledAt.isBefore(DateTime.now()) ||
        task.scheduledAt.isAtSameMomentAs(DateTime.now())) {
      await _tryExecuteTask(task);
    }
  }

  /// Cancel a scheduled task
  Future<void> cancelTask(String taskId) async {
    debugPrint('Cancelling task: $taskId');

    // Cancel running isolate if exists
    final isolate = _runningIsolates[taskId];
    if (isolate != null) {
      isolate.kill(priority: Isolate.immediate);
      _runningIsolates.remove(taskId);
      _isolateReceivePorts[taskId]?.close();
      _isolateReceivePorts.remove(taskId);
    }

    // Update status
    _taskStatuses[taskId] = TaskStatus.cancelled;
    _pendingTasks.remove(taskId);

    _notifyStatusChange();
  }

  /// Get task status
  TaskStatus? getTaskStatus(String taskId) {
    return _taskStatuses[taskId];
  }

  /// Start the task scheduler
  void _startTaskScheduler() {
    _taskScheduler = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _processPendingTasks();
    });
  }

  /// Start the cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _cleanupCompletedTasks();
    });
  }

  /// Process pending tasks
  Future<void> _processPendingTasks() async {
    if (_pendingTasks.isEmpty) return;

    final now = DateTime.now();
    final readyTasks = _pendingTasks.values
        .where(
          (task) =>
              task.scheduledAt.isBefore(now) ||
              task.scheduledAt.isAtSameMomentAs(now),
        )
        .toList();

    // Sort by priority (highest first)
    readyTasks.sort((a, b) => b.priority.value.compareTo(a.priority.value));

    for (final task in readyTasks) {
      if (_taskStatuses[task.id] == TaskStatus.pending) {
        await _tryExecuteTask(task);
      }
    }
  }

  /// Try to execute a task if conditions are met
  Future<void> _tryExecuteTask(BackgroundTask task) async {
    // Check if network is required and available
    if (task.requiresNetwork && !_connectivityService.isConnected) {
      debugPrint('Task ${task.id} requires network but device is offline');
      return;
    }

    // Check if we have too many running tasks (limit to 3 concurrent)
    if (_runningIsolates.length >= 3) {
      debugPrint('Too many concurrent tasks, deferring ${task.id}');
      return;
    }

    await _executeTask(task);
  }

  /// Execute a background task in an isolate
  Future<void> _executeTask(BackgroundTask task) async {
    debugPrint('Executing task: ${task.id}');

    _taskStatuses[task.id] = TaskStatus.running;
    _notifyStatusChange();

    final startTime = DateTime.now();

    try {
      // Create receive port for isolate communication
      final receivePort = ReceivePort();
      _isolateReceivePorts[task.id] = receivePort;

      // Spawn isolate
      final isolate = await Isolate.spawn(
        _taskExecutor,
        _TaskExecutorParams(task: task, sendPort: receivePort.sendPort),
      );

      _runningIsolates[task.id] = isolate;

      // Listen for results with timeout
      final completer = Completer<TaskResult>();
      late StreamSubscription subscription;

      subscription = receivePort.listen((message) {
        if (message is TaskResult) {
          subscription.cancel();
          completer.complete(message);
        } else if (message is String && message.startsWith('ERROR:')) {
          subscription.cancel();
          completer.complete(
            TaskResult(
              taskId: task.id,
              success: false,
              error: message.substring(6),
              executionTime: DateTime.now().difference(startTime),
            ),
          );
        }
      });

      // Wait for result with timeout
      final timeout = task.timeout ?? const Duration(minutes: 10);
      final result = await completer.future.timeout(timeout);

      // Clean up
      isolate.kill(priority: Isolate.immediate);
      _runningIsolates.remove(task.id);
      _isolateReceivePorts.remove(task.id);
      receivePort.close();

      // Update status
      _taskStatuses[task.id] = result.success
          ? TaskStatus.completed
          : TaskStatus.failed;
      _pendingTasks.remove(task.id);

      // Notify result
      _taskResultController.add(result);
      _notifyStatusChange();

      debugPrint(
        'Task ${task.id} ${result.success ? 'completed' : 'failed'} in ${result.executionTime.inSeconds}s',
      );
    } catch (e) {
      debugPrint('Task ${task.id} execution error: $e');

      // Clean up on error
      final isolate = _runningIsolates[task.id];
      if (isolate != null) {
        isolate.kill(priority: Isolate.immediate);
        _runningIsolates.remove(task.id);
      }
      _isolateReceivePorts[task.id]?.close();
      _isolateReceivePorts.remove(task.id);

      // Update status
      _taskStatuses[task.id] = TaskStatus.failed;
      _pendingTasks.remove(task.id);

      // Create error result
      final result = TaskResult(
        taskId: task.id,
        success: false,
        error: e.toString(),
        executionTime: DateTime.now().difference(startTime),
      );

      _taskResultController.add(result);
      _notifyStatusChange();
    }
  }

  /// Static method to execute tasks in isolate
  static void _taskExecutor(_TaskExecutorParams params) async {
    try {
      final task = params.task;
      final sendPort = params.sendPort;

      TaskResult result;

      switch (task.type) {
        case BackgroundTaskType.sync:
          result = await _executeSyncTask(task);
          break;
        case BackgroundTaskType.documentProcessing:
          result = await _executeDocumentProcessingTask(task);
          break;
        case BackgroundTaskType.cacheCleanup:
          result = await _executeCacheCleanupTask(task);
          break;
        case BackgroundTaskType.indexing:
          result = await _executeIndexingTask(task);
          break;
        case BackgroundTaskType.notification:
          result = await _executeNotificationTask(task);
          break;
      }

      sendPort.send(result);
    } catch (e) {
      params.sendPort.send('ERROR: $e');
    }
  }

  /// Execute sync task
  static Future<TaskResult> _executeSyncTask(BackgroundTask task) async {
    final startTime = DateTime.now();

    try {
      // This would integrate with the actual sync service
      // For now, simulate sync operation
      await Future.delayed(const Duration(seconds: 2));

      return TaskResult(
        taskId: task.id,
        success: true,
        data: {'synced_items': 10},
        executionTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return TaskResult(
        taskId: task.id,
        success: false,
        error: e.toString(),
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Execute document processing task
  static Future<TaskResult> _executeDocumentProcessingTask(
    BackgroundTask task,
  ) async {
    final startTime = DateTime.now();

    try {
      // Simulate document processing
      await Future.delayed(const Duration(seconds: 5));

      return TaskResult(
        taskId: task.id,
        success: true,
        data: {'processed_documents': 1},
        executionTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return TaskResult(
        taskId: task.id,
        success: false,
        error: e.toString(),
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Execute cache cleanup task
  static Future<TaskResult> _executeCacheCleanupTask(
    BackgroundTask task,
  ) async {
    final startTime = DateTime.now();

    try {
      // Simulate cache cleanup
      await Future.delayed(const Duration(seconds: 1));

      return TaskResult(
        taskId: task.id,
        success: true,
        data: {'cleaned_bytes': 1024 * 1024 * 50}, // 50MB
        executionTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return TaskResult(
        taskId: task.id,
        success: false,
        error: e.toString(),
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Execute indexing task
  static Future<TaskResult> _executeIndexingTask(BackgroundTask task) async {
    final startTime = DateTime.now();

    try {
      // Simulate indexing
      await Future.delayed(const Duration(seconds: 3));

      return TaskResult(
        taskId: task.id,
        success: true,
        data: {'indexed_documents': 5},
        executionTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return TaskResult(
        taskId: task.id,
        success: false,
        error: e.toString(),
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Execute notification task
  static Future<TaskResult> _executeNotificationTask(
    BackgroundTask task,
  ) async {
    final startTime = DateTime.now();

    try {
      // Simulate notification processing
      await Future.delayed(const Duration(milliseconds: 500));

      return TaskResult(
        taskId: task.id,
        success: true,
        data: {'notifications_sent': 1},
        executionTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return TaskResult(
        taskId: task.id,
        success: false,
        error: e.toString(),
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(bool isConnected) {
    if (isConnected) {
      debugPrint('Network connected, processing network-dependent tasks');
      _processPendingTasks();
    } else {
      debugPrint('Network disconnected, pausing network-dependent tasks');
    }
  }

  /// Handle job queue status changes
  void _onJobQueueStatusChanged(JobQueueStatus status) {
    if (status.hasWork && _connectivityService.isConnected) {
      // Schedule sync task if there are pending jobs
      final syncTask = BackgroundTask(
        id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
        type: BackgroundTaskType.sync,
        priority: TaskPriority.high,
        payload: {'trigger': 'job_queue_change'},
        scheduledAt: DateTime.now(),
        requiresNetwork: true,
      );

      scheduleTask(syncTask);
    }
  }

  /// Clean up completed tasks
  Future<void> _cleanupCompletedTasks() async {
    final completedTaskIds = _taskStatuses.entries
        .where(
          (entry) =>
              entry.value == TaskStatus.completed ||
              entry.value == TaskStatus.failed ||
              entry.value == TaskStatus.cancelled,
        )
        .map((entry) => entry.key)
        .toList();

    for (final taskId in completedTaskIds) {
      _taskStatuses.remove(taskId);
    }

    if (completedTaskIds.isNotEmpty) {
      debugPrint('Cleaned up ${completedTaskIds.length} completed tasks');
      _notifyStatusChange();
    }
  }

  /// Notify status change
  void _notifyStatusChange() {
    _taskStatusController.add(Map.from(_taskStatuses));
  }

  /// Schedule periodic sync task
  Future<void> schedulePeriodicSync({
    Duration interval = const Duration(minutes: 15),
  }) async {
    final task = BackgroundTask(
      id: 'periodic_sync_${DateTime.now().millisecondsSinceEpoch}',
      type: BackgroundTaskType.sync,
      priority: TaskPriority.normal,
      payload: {'type': 'periodic'},
      scheduledAt: DateTime.now().add(interval),
      requiresNetwork: true,
    );

    await scheduleTask(task);
  }

  /// Schedule cache cleanup task
  Future<void> scheduleCacheCleanup({
    Duration delay = const Duration(hours: 1),
  }) async {
    final task = BackgroundTask(
      id: 'cache_cleanup_${DateTime.now().millisecondsSinceEpoch}',
      type: BackgroundTaskType.cacheCleanup,
      priority: TaskPriority.low,
      payload: {},
      scheduledAt: DateTime.now().add(delay),
      requiresNetwork: false,
    );

    await scheduleTask(task);
  }

  /// Get background task statistics
  Map<String, dynamic> getStatistics() {
    final statusCounts = <TaskStatus, int>{};
    for (final status in _taskStatuses.values) {
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return {
      'total_tasks': _taskStatuses.length,
      'pending_tasks': _pendingTasks.length,
      'running_isolates': _runningIsolates.length,
      'status_counts': statusCounts.map((k, v) => MapEntry(k.name, v)),
      'is_running': _isServiceRunning,
    };
  }

  /// Dispose resources and cleanup
  Future<void> dispose() async {
    debugPrint('Disposing BackgroundTaskService');

    _isServiceRunning = false;

    // Cancel timers
    _taskScheduler?.cancel();
    _cleanupTimer?.cancel();

    // Kill all running isolates
    for (final isolate in _runningIsolates.values) {
      isolate.kill(priority: Isolate.immediate);
    }
    _runningIsolates.clear();

    // Close receive ports
    for (final port in _isolateReceivePorts.values) {
      port.close();
    }
    _isolateReceivePorts.clear();

    // Clear pending tasks
    _pendingTasks.clear();
    _taskStatuses.clear();

    // Close streams
    await _taskResultController.close();
    await _taskStatusController.close();

    debugPrint('BackgroundTaskService disposed');
  }
}

/// Parameters for task executor isolate
class _TaskExecutorParams {
  final BackgroundTask task;
  final SendPort sendPort;

  const _TaskExecutorParams({required this.task, required this.sendPort});
}
