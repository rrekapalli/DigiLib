import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sync_service.dart';
import 'job_queue_service.dart';
import '../network/connectivity_service.dart';

/// Service for scheduling background synchronization on mobile platforms
class BackgroundSyncScheduler {
  static const MethodChannel _channel = MethodChannel('digi_lib_app/background_sync');
  
  final SyncService _syncService;
  final JobQueueService _jobQueueService;
  final ConnectivityService _connectivityService;
  
  Timer? _periodicSyncTimer;
  bool _isBackgroundSyncEnabled = true;

  BackgroundSyncScheduler({
    required SyncService syncService,
    required JobQueueService jobQueueService,
    required ConnectivityService connectivityService,
  }) : _syncService = syncService,
       _jobQueueService = jobQueueService,
       _connectivityService = connectivityService {
    _initializeBackgroundSync();
  }

  /// Initialize background sync scheduling
  void _initializeBackgroundSync() {
    if (kIsWeb) {
      // Web doesn't support background sync
      debugPrint('Background sync not supported on web platform');
      return;
    }

    if (Platform.isAndroid) {
      _initializeAndroidBackgroundSync();
    } else if (Platform.isIOS) {
      _initializeIOSBackgroundSync();
    } else {
      // Desktop platforms - use periodic timer
      _initializeDesktopBackgroundSync();
    }

    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen((isConnected) {
      if (isConnected && _isBackgroundSyncEnabled) {
        _triggerSyncIfNeeded();
      }
    });

    // Listen to job queue changes
    _jobQueueService.statusStream.listen((status) {
      if (status.hasWork && _connectivityService.isConnected && _isBackgroundSyncEnabled) {
        _triggerSyncIfNeeded();
      }
    });
  }

  /// Initialize Android background sync using WorkManager
  Future<void> _initializeAndroidBackgroundSync() async {
    try {
      await _channel.invokeMethod('initializeWorkManager', {
        'syncIntervalMinutes': 15, // Minimum interval for WorkManager
        'requiresCharging': false,
        'requiresWifi': false,
        'requiresDeviceIdle': false,
      });
      
      debugPrint('Android WorkManager initialized for background sync');
    } catch (e) {
      debugPrint('Failed to initialize Android background sync: $e');
      _fallbackToPeriodicSync();
    }
  }

  /// Initialize iOS background sync using Background App Refresh
  Future<void> _initializeIOSBackgroundSync() async {
    try {
      await _channel.invokeMethod('initializeBackgroundAppRefresh', {
        'identifier': 'com.digilib.sync',
        'minimumInterval': 900, // 15 minutes minimum for iOS
      });
      
      debugPrint('iOS Background App Refresh initialized for sync');
    } catch (e) {
      debugPrint('Failed to initialize iOS background sync: $e');
      _fallbackToPeriodicSync();
    }
  }

  /// Initialize desktop background sync using periodic timer
  void _initializeDesktopBackgroundSync() {
    _fallbackToPeriodicSync();
  }

  /// Fallback to periodic sync when platform-specific background sync fails
  void _fallbackToPeriodicSync() {
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isBackgroundSyncEnabled && _connectivityService.isConnected) {
        _triggerSyncIfNeeded();
      }
    });
    
    debugPrint('Using periodic timer for background sync');
  }

  /// Trigger sync if there are pending jobs or it's been a while since last sync
  Future<void> _triggerSyncIfNeeded() async {
    try {
      // Check if sync is already in progress
      if (_syncService.isSyncing) {
        debugPrint('Sync already in progress, skipping background trigger');
        return;
      }

      // Check if there are pending jobs
      final hasPendingJobs = await _jobQueueService.hasPendingJobs();
      
      // Check time since last sync (implement this in sync service)
      final shouldPeriodicSync = await _shouldPerformPeriodicSync();

      if (hasPendingJobs || shouldPeriodicSync) {
        debugPrint('Triggering background sync - pending jobs: $hasPendingJobs, periodic: $shouldPeriodicSync');
        await _syncService.performDeltaSync();
      }
      
    } catch (e) {
      debugPrint('Error in background sync trigger: $e');
    }
  }

  /// Check if periodic sync should be performed
  Future<bool> _shouldPerformPeriodicSync() async {
    // This would check the last sync timestamp and determine if enough time has passed
    // For now, return false to only sync when there are pending jobs
    return false;
  }

  /// Enable or disable background sync
  Future<void> setBackgroundSyncEnabled(bool enabled) async {
    _isBackgroundSyncEnabled = enabled;
    
    if (enabled) {
      await _scheduleBackgroundSync();
    } else {
      await _cancelBackgroundSync();
    }
    
    debugPrint('Background sync ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Schedule background sync task
  Future<void> _scheduleBackgroundSync() async {
    if (kIsWeb) return;

    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('scheduleWorkManagerTask');
      } else if (Platform.isIOS) {
        await _channel.invokeMethod('scheduleBackgroundTask');
      }
    } catch (e) {
      debugPrint('Failed to schedule background sync: $e');
    }
  }

  /// Cancel background sync task
  Future<void> _cancelBackgroundSync() async {
    if (kIsWeb) return;

    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('cancelWorkManagerTask');
      } else if (Platform.isIOS) {
        await _channel.invokeMethod('cancelBackgroundTask');
      }
    } catch (e) {
      debugPrint('Failed to cancel background sync: $e');
    }
  }

  /// Handle background sync execution (called from platform code)
  static Future<void> handleBackgroundSync() async {
    try {
      debugPrint('Executing background sync task');
      
      // This would be called from platform-specific background task
      // For now, we'll just log the execution
      // In a real implementation, this would:
      // 1. Initialize necessary services
      // 2. Perform sync operation
      // 3. Handle results and cleanup
      
      debugPrint('Background sync task completed');
    } catch (e) {
      debugPrint('Background sync task failed: $e');
    }
  }

  /// Get background sync status
  Future<Map<String, dynamic>> getBackgroundSyncStatus() async {
    try {
      if (kIsWeb) {
        return {
          'supported': false,
          'enabled': false,
          'reason': 'Web platform does not support background sync',
        };
      }

      final result = await _channel.invokeMethod('getBackgroundSyncStatus');
      return Map<String, dynamic>.from(result);
      
    } catch (e) {
      return {
        'supported': false,
        'enabled': _isBackgroundSyncEnabled,
        'error': e.toString(),
      };
    }
  }

  /// Request background sync permissions (Android 6+, iOS)
  Future<bool> requestBackgroundSyncPermissions() async {
    if (kIsWeb) return false;

    try {
      final result = await _channel.invokeMethod('requestBackgroundPermissions');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('Failed to request background sync permissions: $e');
      return false;
    }
  }

  /// Check if background sync permissions are granted
  Future<bool> hasBackgroundSyncPermissions() async {
    if (kIsWeb) return false;

    try {
      final result = await _channel.invokeMethod('hasBackgroundPermissions');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('Failed to check background sync permissions: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _periodicSyncTimer?.cancel();
  }
}