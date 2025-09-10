import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'mobile_ui_service.dart';
import 'background_service.dart';
import 'gesture_service.dart';
import 'notification_service.dart';
import 'screen_service.dart';

/// Main service for coordinating all mobile-specific integrations
class MobileIntegrationService {
  static bool _isInitialized = false;
  static NotificationConfig _notificationConfig = const NotificationConfig();
  
  /// Initialize all mobile services
  static Future<void> initialize({
    NotificationConfig notificationConfig = const NotificationConfig(),
    bool enableBackgroundSync = true,
    bool enableGestureOptimizations = true,
  }) async {
    if (!_isMobile || _isInitialized) return;
    
    try {
      _notificationConfig = notificationConfig;
      
      // Initialize background service
      if (enableBackgroundSync) {
        await BackgroundService.initialize();
      }
      
      // Initialize notification service
      await MobileNotificationService.initialize();
      
      // Set up initial screen configuration
      await _setupInitialScreenConfiguration();
      
      // Configure system UI
      await _configureSystemUI();
      
      _isInitialized = true;
      print('Mobile integration services initialized successfully');
    } catch (e) {
      print('Error initializing mobile services: $e');
    }
  }
  
  /// Set up initial screen configuration
  static Future<void> _setupInitialScreenConfiguration() async {
    try {
      // Allow all orientations by default
      await ScreenService.allowAllOrientations();
      
      // Set system UI overlay style
      await ScreenService.setSystemUIOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      );
    } catch (e) {
      print('Error setting up screen configuration: $e');
    }
  }
  
  /// Configure system UI for mobile
  static Future<void> _configureSystemUI() async {
    try {
      // Show system UI by default
      await ScreenService.showSystemUI();
    } catch (e) {
      print('Error configuring system UI: $e');
    }
  }
  
  /// Handle app lifecycle changes
  static Future<void> handleAppLifecycle(AppLifecycleState state) async {
    if (!_isInitialized) return;
    
    switch (state) {
      case AppLifecycleState.paused:
        await _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        await _handleAppResumed();
        break;
      case AppLifecycleState.detached:
        await dispose();
        break;
      default:
        break;
    }
  }
  
  /// Handle app paused state
  static Future<void> _handleAppPaused() async {
    try {
      // Disable wakelock when app is paused
      await BackgroundService.disableWakelock();
      
      // Schedule background sync if enabled
      if (_notificationConfig.enableSyncNotifications) {
        await BackgroundService.scheduleBackgroundSync();
      }
    } catch (e) {
      print('Error handling app paused: $e');
    }
  }
  
  /// Handle app resumed state
  static Future<void> _handleAppResumed() async {
    try {
      // Check for any pending notifications
      final pendingNotifications = await MobileNotificationService.getPendingNotifications();
      print('Pending notifications: ${pendingNotifications.length}');
      
      // Restore screen configuration if needed
      await _setupInitialScreenConfiguration();
    } catch (e) {
      print('Error handling app resumed: $e');
    }
  }
  
  /// Configure for reading mode
  static Future<void> enableReadingMode({
    bool lockOrientation = false,
    double? brightness,
    bool hideSystemUI = false,
  }) async {
    if (!_isInitialized) return;
    
    try {
      await ScreenService.enableReadingMode(
        lockOrientation: lockOrientation,
        brightness: brightness,
        hideSystemUI: hideSystemUI,
      );
      
      // Enable wakelock during reading to prevent screen timeout
      await BackgroundService.enableWakelock();
      
      print('Reading mode enabled');
    } catch (e) {
      print('Error enabling reading mode: $e');
    }
  }
  
  /// Disable reading mode
  static Future<void> disableReadingMode() async {
    if (!_isInitialized) return;
    
    try {
      await ScreenService.disableReadingMode();
      
      // Disable wakelock when not reading
      await BackgroundService.disableWakelock();
      
      print('Reading mode disabled');
    } catch (e) {
      print('Error disabling reading mode: $e');
    }
  }
  
  /// Show sync completion notification
  static Future<void> notifySyncComplete({
    required int documentsCount,
    String? libraryName,
  }) async {
    if (!_isInitialized || !_notificationConfig.enableSyncNotifications) return;
    
    await MobileNotificationService.showSyncCompletionNotification(
      documentsCount: documentsCount,
      libraryName: libraryName,
    );
  }
  
  /// Show download progress notification
  static Future<void> notifyDownloadProgress({
    required String documentTitle,
    required int progress,
  }) async {
    if (!_isInitialized || !_notificationConfig.enableDownloadNotifications) return;
    
    await MobileNotificationService.showDownloadProgressNotification(
      documentTitle: documentTitle,
      progress: progress,
    );
  }
  
  /// Show error notification
  static Future<void> notifyError({
    required String title,
    required String message,
  }) async {
    if (!_isInitialized || !_notificationConfig.enableErrorNotifications) return;
    
    await MobileNotificationService.showErrorNotification(
      title: title,
      message: message,
    );
  }
  
  /// Schedule reading reminder
  static Future<void> scheduleReadingReminder({
    required String documentTitle,
    required int lastPage,
    DateTime? reminderTime,
  }) async {
    if (!_isInitialized || !_notificationConfig.enableReadingReminders) return;
    
    final scheduledTime = reminderTime ?? 
        DateTime.now().add(_notificationConfig.readingReminderInterval);
    
    await MobileNotificationService.scheduleNotification(
      id: documentTitle.hashCode,
      title: 'Continue Reading',
      body: 'You left off at page $lastPage in $documentTitle',
      scheduledDate: scheduledTime,
      payload: 'reading_reminder:$documentTitle:$lastPage',
    );
  }
  
  /// Get optimal layout configuration for current screen
  static LayoutConfig getOptimalLayout(BuildContext context) {
    return ScreenService.getOptimalLayout(context);
  }
  
  /// Get responsive padding for current screen
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return ScreenService.getResponsivePadding(context);
  }
  
  /// Get responsive column count for grids
  static int getResponsiveColumnCount(BuildContext context) {
    return ScreenService.getResponsiveColumnCount(context);
  }
  
  /// Create mobile-optimized gesture detector
  static Widget createOptimizedGestureDetector({
    required Widget child,
    required BuildContext context,
    
    // Reading gestures
    VoidCallback? onNextPage,
    VoidCallback? onPreviousPage,
    Function(double scale)? onZoom,
    VoidCallback? onDoubleTapZoom,
    
    // Navigation gestures
    VoidCallback? onSwipeBack,
    VoidCallback? onSwipeForward,
    
    // Menu gestures
    VoidCallback? onLongPressMenu,
  }) {
    if (!_isInitialized) return child;
    
    return GestureService.createMultiGestureDetector(
      onSwipeLeft: onNextPage ?? onSwipeForward,
      onSwipeRight: onPreviousPage ?? onSwipeBack,
      onDoubleTap: onDoubleTapZoom,
      onScaleUpdate: onZoom,
      onLongPress: onLongPressMenu,
      child: child,
    );
  }
  
  /// Get current device information
  static Future<MobileDeviceInfo> getDeviceInfo(BuildContext context) async {
    return MobileDeviceInfo(
      isTablet: ScreenService.isTablet(context),
      isLandscape: ScreenService.isLandscape(context),
      screenSize: ScreenService.getScreenSize(context),
      density: ScreenService.getScreenDensity(context),
      safeAreaInsets: ScreenService.getSafeAreaInsets(context),
      batteryLevel: await BackgroundService.getBatteryLevel(),
      isCharging: await BackgroundService.isCharging(),
      isOnWifi: await BackgroundService.isOnWifi(),
      hasLowBattery: await BackgroundService.hasLowBattery(),
    );
  }
  
  /// Optimize performance based on device conditions
  static Future<PerformanceOptimization> getPerformanceOptimization() async {
    final batteryLevel = await BackgroundService.getBatteryLevel();
    final isCharging = await BackgroundService.isCharging();
    final isOnWifi = await BackgroundService.isOnWifi();
    
    if (batteryLevel <= 10 && !isCharging) {
      return PerformanceOptimization.minimal;
    }
    
    if (batteryLevel <= 20 && !isCharging) {
      return PerformanceOptimization.reduced;
    }
    
    if (!isOnWifi && !isCharging) {
      return PerformanceOptimization.balanced;
    }
    
    return PerformanceOptimization.full;
  }
  
  /// Update notification configuration
  static void updateNotificationConfig(NotificationConfig config) {
    _notificationConfig = config;
  }
  
  /// Check if mobile services are available
  static bool get isAvailable => _isInitialized;
  
  /// Dispose all mobile services
  static Future<void> dispose() async {
    if (!_isInitialized) return;
    
    try {
      await BackgroundService.dispose();
      await MobileNotificationService.dispose();
      await ScreenService.dispose();
      
      _isInitialized = false;
      print('Mobile integration services disposed');
    } catch (e) {
      print('Error disposing mobile services: $e');
    }
  }
  
  /// Check if running on mobile platform
  static bool get _isMobile {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }
}

/// Mobile device information
class MobileDeviceInfo {
  final bool isTablet;
  final bool isLandscape;
  final Size screenSize;
  final double density;
  final EdgeInsets safeAreaInsets;
  final int batteryLevel;
  final bool isCharging;
  final bool isOnWifi;
  final bool hasLowBattery;
  
  const MobileDeviceInfo({
    required this.isTablet,
    required this.isLandscape,
    required this.screenSize,
    required this.density,
    required this.safeAreaInsets,
    required this.batteryLevel,
    required this.isCharging,
    required this.isOnWifi,
    required this.hasLowBattery,
  });
  
  @override
  String toString() {
    return 'MobileDeviceInfo(isTablet: $isTablet, isLandscape: $isLandscape, '
           'screenSize: $screenSize, batteryLevel: $batteryLevel%, '
           'isCharging: $isCharging, isOnWifi: $isOnWifi)';
  }
}

/// Performance optimization levels
enum PerformanceOptimization {
  minimal,   // Minimal features, maximum battery saving
  reduced,   // Reduced features, battery saving
  balanced,  // Balanced performance and battery
  full,      // Full features, maximum performance
}