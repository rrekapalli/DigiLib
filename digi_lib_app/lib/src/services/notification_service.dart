import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/entities/share.dart';

/// Types of notifications
enum NotificationType {
  shareInvitation,
  shareAccepted,
  shareRevoked,
  commentAdded,
  documentShared,
  syncCompleted,
  syncFailed,
  scanProgress,
  scanCompleted,
  scanFailed,
  jobCompleted,
  jobFailed,
  backgroundTaskCompleted,
  backgroundTaskFailed,
}

/// Notification model
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.data,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Notification preferences
class NotificationPreferences {
  final bool syncNotifications;
  final bool scanNotifications;
  final bool jobNotifications;
  final bool shareNotifications;
  final bool commentNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String? customSoundPath;

  const NotificationPreferences({
    this.syncNotifications = true,
    this.scanNotifications = true,
    this.jobNotifications = true,
    this.shareNotifications = true,
    this.commentNotifications = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.customSoundPath,
  });

  NotificationPreferences copyWith({
    bool? syncNotifications,
    bool? scanNotifications,
    bool? jobNotifications,
    bool? shareNotifications,
    bool? commentNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? customSoundPath,
  }) {
    return NotificationPreferences(
      syncNotifications: syncNotifications ?? this.syncNotifications,
      scanNotifications: scanNotifications ?? this.scanNotifications,
      jobNotifications: jobNotifications ?? this.jobNotifications,
      shareNotifications: shareNotifications ?? this.shareNotifications,
      commentNotifications: commentNotifications ?? this.commentNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      customSoundPath: customSoundPath ?? this.customSoundPath,
    );
  }
}

/// Service for managing notifications and invitations
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final List<AppNotification> _notifications = [];
  final StreamController<List<AppNotification>> _notificationsController = 
      StreamController<List<AppNotification>>.broadcast();
  final StreamController<AppNotification> _newNotificationController = 
      StreamController<AppNotification>.broadcast();
  
  NotificationPreferences _preferences = const NotificationPreferences();
  bool _isInitialized = false;

  /// Stream of all notifications
  Stream<List<AppNotification>> get notificationsStream => _notificationsController.stream;

  /// Stream of new notifications
  Stream<AppNotification> get newNotificationStream => _newNotificationController.stream;

  /// Get all notifications
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Get current notification preferences
  NotificationPreferences get preferences => _preferences;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('NotificationService already initialized');
      return;
    }

    try {
      await _initializeLocalNotifications();
      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
      rethrow;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    if (kIsWeb) {
      debugPrint('Local notifications not supported on web');
      return;
    }

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Linux initialization settings
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    
    // Handle notification tap based on payload
    if (response.payload != null) {
      // Parse payload and navigate to appropriate screen
      // This would integrate with the app's navigation system
    }
  }

  /// Add a new notification
  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification); // Add to beginning (most recent first)
    _notificationsController.add(_notifications);
    _newNotificationController.add(notification);
    
    // Show local notification if enabled
    await _showLocalNotification(notification);
  }

  /// Show local notification
  Future<void> _showLocalNotification(AppNotification notification) async {
    if (!_isInitialized || kIsWeb) return;

    // Check if this type of notification is enabled
    if (!_isNotificationTypeEnabled(notification.type)) {
      return;
    }

    try {
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _getChannelId(notification.type),
          _getChannelName(notification.type),
          channelDescription: _getChannelDescription(notification.type),
          importance: _getImportance(notification.type),
          priority: _getPriority(notification.type),
          enableVibration: _preferences.vibrationEnabled,
          playSound: _preferences.soundEnabled,
          sound: _preferences.customSoundPath != null 
              ? UriAndroidNotificationSound(_preferences.customSoundPath!)
              : null,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: _preferences.soundEnabled,
          sound: _preferences.customSoundPath,
        ),
        linux: LinuxNotificationDetails(
          actions: [
            const LinuxNotificationAction(
              key: 'open',
              label: 'Open',
            ),
          ],
        ),
      );

      await _localNotifications.show(
        notification.id.hashCode,
        notification.title,
        notification.message,
        notificationDetails,
        payload: notification.id,
      );
    } catch (e) {
      debugPrint('Failed to show local notification: $e');
    }
  }

  /// Check if notification type is enabled
  bool _isNotificationTypeEnabled(NotificationType type) {
    switch (type) {
      case NotificationType.syncCompleted:
      case NotificationType.syncFailed:
        return _preferences.syncNotifications;
      case NotificationType.scanProgress:
      case NotificationType.scanCompleted:
      case NotificationType.scanFailed:
        return _preferences.scanNotifications;
      case NotificationType.jobCompleted:
      case NotificationType.jobFailed:
      case NotificationType.backgroundTaskCompleted:
      case NotificationType.backgroundTaskFailed:
        return _preferences.jobNotifications;
      case NotificationType.shareInvitation:
      case NotificationType.shareAccepted:
      case NotificationType.shareRevoked:
      case NotificationType.documentShared:
        return _preferences.shareNotifications;
      case NotificationType.commentAdded:
        return _preferences.commentNotifications;
    }
  }

  /// Get notification channel ID
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.syncCompleted:
      case NotificationType.syncFailed:
        return 'sync_notifications';
      case NotificationType.scanProgress:
      case NotificationType.scanCompleted:
      case NotificationType.scanFailed:
        return 'scan_notifications';
      case NotificationType.jobCompleted:
      case NotificationType.jobFailed:
      case NotificationType.backgroundTaskCompleted:
      case NotificationType.backgroundTaskFailed:
        return 'job_notifications';
      case NotificationType.shareInvitation:
      case NotificationType.shareAccepted:
      case NotificationType.shareRevoked:
      case NotificationType.documentShared:
        return 'share_notifications';
      case NotificationType.commentAdded:
        return 'comment_notifications';
    }
  }

  /// Get notification channel name
  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.syncCompleted:
      case NotificationType.syncFailed:
        return 'Sync Notifications';
      case NotificationType.scanProgress:
      case NotificationType.scanCompleted:
      case NotificationType.scanFailed:
        return 'Scan Notifications';
      case NotificationType.jobCompleted:
      case NotificationType.jobFailed:
      case NotificationType.backgroundTaskCompleted:
      case NotificationType.backgroundTaskFailed:
        return 'Job Notifications';
      case NotificationType.shareInvitation:
      case NotificationType.shareAccepted:
      case NotificationType.shareRevoked:
      case NotificationType.documentShared:
        return 'Share Notifications';
      case NotificationType.commentAdded:
        return 'Comment Notifications';
    }
  }

  /// Get notification channel description
  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.syncCompleted:
      case NotificationType.syncFailed:
        return 'Notifications for sync operations';
      case NotificationType.scanProgress:
      case NotificationType.scanCompleted:
      case NotificationType.scanFailed:
        return 'Notifications for library scan operations';
      case NotificationType.jobCompleted:
      case NotificationType.jobFailed:
      case NotificationType.backgroundTaskCompleted:
      case NotificationType.backgroundTaskFailed:
        return 'Notifications for background job completion';
      case NotificationType.shareInvitation:
      case NotificationType.shareAccepted:
      case NotificationType.shareRevoked:
      case NotificationType.documentShared:
        return 'Notifications for document sharing';
      case NotificationType.commentAdded:
        return 'Notifications for new comments';
    }
  }

  /// Get notification importance
  Importance _getImportance(NotificationType type) {
    switch (type) {
      case NotificationType.syncFailed:
      case NotificationType.scanFailed:
      case NotificationType.jobFailed:
      case NotificationType.backgroundTaskFailed:
        return Importance.high;
      case NotificationType.shareInvitation:
      case NotificationType.commentAdded:
        return Importance.defaultImportance;
      default:
        return Importance.low;
    }
  }

  /// Get notification priority
  Priority _getPriority(NotificationType type) {
    switch (type) {
      case NotificationType.syncFailed:
      case NotificationType.scanFailed:
      case NotificationType.jobFailed:
      case NotificationType.backgroundTaskFailed:
        return Priority.high;
      case NotificationType.shareInvitation:
      case NotificationType.commentAdded:
        return Priority.defaultPriority;
      default:
        return Priority.low;
    }
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notificationsController.add(_notifications);
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _notificationsController.add(_notifications);
  }

  /// Remove a notification
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _notificationsController.add(_notifications);
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    _notificationsController.add(_notifications);
  }

  /// Send share invitation notification
  Future<void> sendShareInvitation(Share share, String inviterName, String documentTitle) async {
    final notification = AppNotification(
      id: 'share_${share.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.shareInvitation,
      title: 'Document Shared',
      message: '$inviterName shared "$documentTitle" with you',
      timestamp: DateTime.now(),
      data: {
        'share_id': share.id,
        'document_id': share.subjectId,
        'document_title': documentTitle,
        'inviter_name': inviterName,
        'permission': share.permission.name,
      },
    );
    
    await addNotification(notification);
  }

  /// Send comment notification
  Future<void> sendCommentNotification(String documentId, String documentTitle, String commenterName, int pageNumber) async {
    final notification = AppNotification(
      id: 'comment_${documentId}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.commentAdded,
      title: 'New Comment',
      message: '$commenterName added a comment on page $pageNumber of "$documentTitle"',
      timestamp: DateTime.now(),
      data: {
        'document_id': documentId,
        'document_title': documentTitle,
        'commenter_name': commenterName,
        'page_number': pageNumber,
      },
    );
    
    await addNotification(notification);
  }

  /// Send sync completion notification
  Future<void> sendSyncCompletedNotification(int itemsSynced) async {
    final notification = AppNotification(
      id: 'sync_completed_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.syncCompleted,
      title: 'Sync Completed',
      message: 'Successfully synced $itemsSynced items',
      timestamp: DateTime.now(),
      data: {'items_synced': itemsSynced},
    );
    
    await addNotification(notification);
  }

  /// Send sync failed notification
  Future<void> sendSyncFailedNotification(String error) async {
    final notification = AppNotification(
      id: 'sync_failed_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.syncFailed,
      title: 'Sync Failed',
      message: 'Failed to sync: $error',
      timestamp: DateTime.now(),
      data: {'error': error},
    );
    
    await addNotification(notification);
  }

  /// Send document shared notification
  Future<void> sendDocumentSharedNotification(String documentTitle, String recipientEmail) async {
    final notification = AppNotification(
      id: 'doc_shared_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.documentShared,
      title: 'Document Shared',
      message: 'Successfully shared "$documentTitle" with $recipientEmail',
      timestamp: DateTime.now(),
      data: {
        'document_title': documentTitle,
        'recipient_email': recipientEmail,
      },
    );
    
    await addNotification(notification);
  }

  /// Send scan progress notification
  Future<void> sendScanProgressNotification(String libraryName, int progress, int total) async {
    final notification = AppNotification(
      id: 'scan_progress_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.scanProgress,
      title: 'Scanning Library',
      message: 'Scanning "$libraryName": $progress of $total documents processed',
      timestamp: DateTime.now(),
      data: {
        'library_name': libraryName,
        'progress': progress,
        'total': total,
      },
    );
    
    await addNotification(notification);
  }

  /// Send scan completed notification
  Future<void> sendScanCompletedNotification(String libraryName, int documentsFound) async {
    final notification = AppNotification(
      id: 'scan_completed_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.scanCompleted,
      title: 'Scan Completed',
      message: 'Successfully scanned "$libraryName" and found $documentsFound documents',
      timestamp: DateTime.now(),
      data: {
        'library_name': libraryName,
        'documents_found': documentsFound,
      },
    );
    
    await addNotification(notification);
  }

  /// Send scan failed notification
  Future<void> sendScanFailedNotification(String libraryName, String error) async {
    final notification = AppNotification(
      id: 'scan_failed_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.scanFailed,
      title: 'Scan Failed',
      message: 'Failed to scan "$libraryName": $error',
      timestamp: DateTime.now(),
      data: {
        'library_name': libraryName,
        'error': error,
      },
    );
    
    await addNotification(notification);
  }

  /// Send job completed notification
  Future<void> sendJobCompletedNotification(String jobType, Map<String, dynamic>? result) async {
    final notification = AppNotification(
      id: 'job_completed_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.jobCompleted,
      title: 'Job Completed',
      message: 'Successfully completed $jobType job',
      timestamp: DateTime.now(),
      data: {
        'job_type': jobType,
        'result': result,
      },
    );
    
    await addNotification(notification);
  }

  /// Send job failed notification
  Future<void> sendJobFailedNotification(String jobType, String error) async {
    final notification = AppNotification(
      id: 'job_failed_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.jobFailed,
      title: 'Job Failed',
      message: 'Failed to complete $jobType job: $error',
      timestamp: DateTime.now(),
      data: {
        'job_type': jobType,
        'error': error,
      },
    );
    
    await addNotification(notification);
  }

  /// Send background task completed notification
  Future<void> sendBackgroundTaskCompletedNotification(String taskType, Map<String, dynamic>? result) async {
    final notification = AppNotification(
      id: 'bg_task_completed_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.backgroundTaskCompleted,
      title: 'Background Task Completed',
      message: 'Successfully completed $taskType task',
      timestamp: DateTime.now(),
      data: {
        'task_type': taskType,
        'result': result,
      },
    );
    
    await addNotification(notification);
  }

  /// Send background task failed notification
  Future<void> sendBackgroundTaskFailedNotification(String taskType, String error) async {
    final notification = AppNotification(
      id: 'bg_task_failed_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.backgroundTaskFailed,
      title: 'Background Task Failed',
      message: 'Failed to complete $taskType task: $error',
      timestamp: DateTime.now(),
      data: {
        'task_type': taskType,
        'error': error,
      },
    );
    
    await addNotification(notification);
  }

  /// Get notifications by type
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get unread notifications
  List<AppNotification> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Update notification preferences
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    _preferences = preferences;
    
    // Save preferences to storage (would integrate with secure storage)
    debugPrint('Notification preferences updated');
  }

  /// Load notification preferences from storage
  Future<void> loadPreferences() async {
    // This would load from secure storage
    // For now, use defaults
    _preferences = const NotificationPreferences();
    debugPrint('Notification preferences loaded');
  }

  /// Cancel all local notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized || kIsWeb) return;
    
    try {
      await _localNotifications.cancelAll();
      debugPrint('All local notifications cancelled');
    } catch (e) {
      debugPrint('Failed to cancel notifications: $e');
    }
  }

  /// Cancel specific notification
  Future<void> cancelNotification(String notificationId) async {
    if (!_isInitialized || kIsWeb) return;
    
    try {
      await _localNotifications.cancel(notificationId.hashCode);
      debugPrint('Cancelled notification: $notificationId');
    } catch (e) {
      debugPrint('Failed to cancel notification $notificationId: $e');
    }
  }

  /// Show progress notification (for long-running operations)
  Future<void> showProgressNotification({
    required String id,
    required String title,
    required String message,
    required int progress,
    required int maxProgress,
    bool indeterminate = false,
  }) async {
    if (!_isInitialized || kIsWeb) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        'progress_notifications',
        'Progress Notifications',
        channelDescription: 'Notifications showing progress of operations',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: maxProgress,
        progress: progress,
        indeterminate: indeterminate,
        ongoing: true,
        autoCancel: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        ),
      );

      await _localNotifications.show(
        id.hashCode,
        title,
        message,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Failed to show progress notification: $e');
    }
  }

  /// Update progress notification
  Future<void> updateProgressNotification({
    required String id,
    required String title,
    required String message,
    required int progress,
    required int maxProgress,
  }) async {
    await showProgressNotification(
      id: id,
      title: title,
      message: message,
      progress: progress,
      maxProgress: maxProgress,
    );
  }

  /// Check if notifications are enabled for the app
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized || kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        final androidImplementation = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await androidImplementation?.areNotificationsEnabled() ?? false;
      } else if (Platform.isIOS) {
        final iosImplementation = _localNotifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final settings = await iosImplementation?.checkPermissions();
        return settings?.isEnabled ?? false;
      }
      return true; // Assume enabled for other platforms
    } catch (e) {
      debugPrint('Failed to check notification permissions: $e');
      return false;
    }
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    if (!_isInitialized || kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        final androidImplementation = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await androidImplementation?.requestNotificationsPermission() ?? false;
      } else if (Platform.isIOS) {
        final iosImplementation = _localNotifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        return await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ?? false;
      }
      return true; // Assume granted for other platforms
    } catch (e) {
      debugPrint('Failed to request notification permissions: $e');
      return false;
    }
  }

  /// Get notification statistics
  Map<String, dynamic> getStatistics() {
    final typeCounts = <NotificationType, int>{};
    for (final notification in _notifications) {
      typeCounts[notification.type] = (typeCounts[notification.type] ?? 0) + 1;
    }

    return {
      'total_notifications': _notifications.length,
      'unread_count': unreadCount,
      'type_counts': typeCounts.map((k, v) => MapEntry(k.name, v)),
      'is_initialized': _isInitialized,
      'preferences': {
        'sync_notifications': _preferences.syncNotifications,
        'scan_notifications': _preferences.scanNotifications,
        'job_notifications': _preferences.jobNotifications,
        'share_notifications': _preferences.shareNotifications,
        'comment_notifications': _preferences.commentNotifications,
        'sound_enabled': _preferences.soundEnabled,
        'vibration_enabled': _preferences.vibrationEnabled,
      },
    };
  }

  /// Show error notification
  Future<void> showErrorNotification(String title, String message, {Map<String, dynamic>? data}) async {
    final notification = AppNotification(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.syncFailed, // Use existing error type
      title: title,
      message: message,
      timestamp: DateTime.now(),
      data: data,
    );
    
    await addNotification(notification);
  }

  /// Show info notification
  Future<void> showInfoNotification(String title, String message, {Map<String, dynamic>? data}) async {
    final notification = AppNotification(
      id: 'info_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.syncCompleted, // Use existing info type
      title: title,
      message: message,
      timestamp: DateTime.now(),
      data: data,
    );
    
    await addNotification(notification);
  }

  /// Dispose resources
  Future<void> dispose() async {
    debugPrint('Disposing NotificationService');
    
    // Cancel all local notifications
    await cancelAllNotifications();
    
    // Close streams
    await _notificationsController.close();
    await _newNotificationController.close();
    
    _isInitialized = false;
    debugPrint('NotificationService disposed');
  }
}