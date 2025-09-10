import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service for handling mobile notifications
class MobileNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  
  /// Initialize notification service
  static Future<void> initialize() async {
    if (!_isMobile || _isInitialized) return;
    
    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      // Combined initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      // Initialize the plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Request permissions for iOS
      if (Platform.isIOS) {
        await _requestIOSPermissions();
      }
      
      _isInitialized = true;
      print('Mobile notification service initialized');
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }
  
  /// Request iOS notification permissions
  static Future<void> _requestIOSPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
  
  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      print('Notification tapped with payload: $payload');
      // Handle navigation based on payload
      _handleNotificationNavigation(payload);
    }
  }
  
  /// Handle navigation from notification
  static void _handleNotificationNavigation(String payload) {
    // Parse payload and navigate accordingly
    // Implementation would depend on your navigation system
    print('Navigating based on notification payload: $payload');
  }
  
  /// Show sync completion notification
  static Future<void> showSyncCompletionNotification({
    required int documentsCount,
    String? libraryName,
  }) async {
    if (!_isInitialized) return;
    
    try {
      const androidDetails = AndroidNotificationDetails(
        'sync_channel',
        'Sync Notifications',
        channelDescription: 'Notifications for sync operations',
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      final title = 'Sync Complete';
      final body = libraryName != null
          ? 'Synced $documentsCount documents in $libraryName'
          : 'Synced $documentsCount documents';
      
      await _notifications.show(
        1,
        title,
        body,
        details,
        payload: 'sync_complete',
      );
    } catch (e) {
      print('Error showing sync notification: $e');
    }
  }
  
  /// Show download progress notification
  static Future<void> showDownloadProgressNotification({
    required String documentTitle,
    required int progress,
  }) async {
    if (!_isInitialized) return;
    
    try {
      final androidDetails = AndroidNotificationDetails(
        'download_channel',
        'Download Notifications',
        channelDescription: 'Notifications for download progress',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
        ongoing: progress < 100,
        autoCancel: false,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      final title = progress < 100 ? 'Downloading...' : 'Download Complete';
      final body = progress < 100 
          ? 'Downloading $documentTitle ($progress%)'
          : '$documentTitle is ready to read';
      
      await _notifications.show(
        2,
        title,
        body,
        details,
        payload: 'download_progress:$documentTitle',
      );
    } catch (e) {
      print('Error showing download notification: $e');
    }
  }
  
  /// Show error notification
  static Future<void> showErrorNotification({
    required String title,
    required String message,
    String? actionPayload,
  }) async {
    if (!_isInitialized) return;
    
    try {
      const androidDetails = AndroidNotificationDetails(
        'error_channel',
        'Error Notifications',
        channelDescription: 'Notifications for errors and issues',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.show(
        3,
        title,
        message,
        details,
        payload: actionPayload ?? 'error',
      );
    } catch (e) {
      print('Error showing error notification: $e');
    }
  }
  
  /// Show reading reminder notification
  static Future<void> showReadingReminderNotification({
    required String documentTitle,
    required int lastPage,
  }) async {
    if (!_isInitialized) return;
    
    try {
      const androidDetails = AndroidNotificationDetails(
        'reminder_channel',
        'Reading Reminders',
        channelDescription: 'Reminders to continue reading',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.show(
        4,
        'Continue Reading',
        'You left off at page $lastPage in $documentTitle',
        details,
        payload: 'reading_reminder:$documentTitle:$lastPage',
      );
    } catch (e) {
      print('Error showing reading reminder: $e');
    }
  }
  
  /// Schedule a notification for later
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) return;
    
    try {
      const androidDetails = AndroidNotificationDetails(
        'scheduled_channel',
        'Scheduled Notifications',
        channelDescription: 'Scheduled notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }
  
  /// Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    
    try {
      await _notifications.cancel(id);
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }
  
  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    
    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('Error canceling all notifications: $e');
    }
  }
  
  /// Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) return [];
    
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }
  
  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) return false;
    
    try {
      if (Platform.isAndroid) {
        final androidImplementation = _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await androidImplementation?.areNotificationsEnabled() ?? false;
      } else if (Platform.isIOS) {
        final iosImplementation = _notifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final settings = await iosImplementation?.checkPermissions();
        return settings?.isEnabled ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking notification permissions: $e');
      return false;
    }
  }
  
  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    if (!_isInitialized) return false;
    
    try {
      if (Platform.isAndroid) {
        final androidImplementation = _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await androidImplementation?.requestNotificationsPermission() ?? false;
      } else if (Platform.isIOS) {
        final iosImplementation = _notifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        return await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ?? false;
      }
      return false;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }
  
  /// Dispose notification service
  static Future<void> dispose() async {
    if (!_isInitialized) return;
    
    try {
      await cancelAllNotifications();
      _isInitialized = false;
      print('Mobile notification service disposed');
    } catch (e) {
      print('Error disposing notification service: $e');
    }
  }
  
  /// Check if running on mobile platform
  static bool get _isMobile {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }
}

/// Notification types for the app
enum NotificationType {
  syncComplete,
  downloadProgress,
  error,
  readingReminder,
  newDocument,
  shareInvitation,
}

/// Notification configuration
class NotificationConfig {
  final bool enableSyncNotifications;
  final bool enableDownloadNotifications;
  final bool enableErrorNotifications;
  final bool enableReadingReminders;
  final Duration readingReminderInterval;
  
  const NotificationConfig({
    this.enableSyncNotifications = true,
    this.enableDownloadNotifications = true,
    this.enableErrorNotifications = true,
    this.enableReadingReminders = false,
    this.readingReminderInterval = const Duration(days: 1),
  });
}