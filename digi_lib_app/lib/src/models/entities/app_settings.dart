import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import '../ui/document_view_settings.dart';

part 'app_settings.g.dart';

/// App settings model for user preferences
@JsonSerializable()
class AppSettings {
  final UISettings ui;
  final SyncSettings sync;
  final CacheSettings cache;
  final NotificationSettings notifications;
  final AccessibilitySettings accessibility;

  const AppSettings({
    required this.ui,
    required this.sync,
    required this.cache,
    required this.notifications,
    required this.accessibility,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);

  AppSettings copyWith({
    UISettings? ui,
    SyncSettings? sync,
    CacheSettings? cache,
    NotificationSettings? notifications,
    AccessibilitySettings? accessibility,
  }) {
    return AppSettings(
      ui: ui ?? this.ui,
      sync: sync ?? this.sync,
      cache: cache ?? this.cache,
      notifications: notifications ?? this.notifications,
      accessibility: accessibility ?? this.accessibility,
    );
  }

  /// Default settings
  static AppSettings get defaultSettings => const AppSettings(
        ui: UISettings.defaultSettings,
        sync: SyncSettings.defaultSettings,
        cache: CacheSettings.defaultSettings,
        notifications: NotificationSettings.defaultSettings,
        accessibility: AccessibilitySettings.defaultSettings,
      );
}

/// UI-related settings
@JsonSerializable()
class UISettings {
  final ThemeMode themeMode;
  final bool useMaterialYou;
  final double textScaleFactor;
  final bool showThumbnails;
  final DocumentViewMode defaultViewMode;
  final DocumentSortBy defaultSortOrder;

  const UISettings({
    required this.themeMode,
    required this.useMaterialYou,
    required this.textScaleFactor,
    required this.showThumbnails,
    required this.defaultViewMode,
    required this.defaultSortOrder,
  });

  factory UISettings.fromJson(Map<String, dynamic> json) =>
      _$UISettingsFromJson(json);

  Map<String, dynamic> toJson() => _$UISettingsToJson(this);

  UISettings copyWith({
    ThemeMode? themeMode,
    bool? useMaterialYou,
    double? textScaleFactor,
    bool? showThumbnails,
    DocumentViewMode? defaultViewMode,
    DocumentSortBy? defaultSortOrder,
  }) {
    return UISettings(
      themeMode: themeMode ?? this.themeMode,
      useMaterialYou: useMaterialYou ?? this.useMaterialYou,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      showThumbnails: showThumbnails ?? this.showThumbnails,
      defaultViewMode: defaultViewMode ?? this.defaultViewMode,
      defaultSortOrder: defaultSortOrder ?? this.defaultSortOrder,
    );
  }

  static const UISettings defaultSettings = UISettings(
    themeMode: ThemeMode.system,
    useMaterialYou: true,
    textScaleFactor: 1.0,
    showThumbnails: true,
    defaultViewMode: DocumentViewMode.grid,
    defaultSortOrder: DocumentSortBy.name,
  );
}

/// Sync-related settings
@JsonSerializable()
class SyncSettings {
  final bool autoSync;
  final int syncIntervalMinutes;
  final bool syncOnWifiOnly;
  final bool backgroundSync;
  final bool syncBookmarks;
  final bool syncComments;
  final bool syncReadingProgress;
  final bool syncTags;

  const SyncSettings({
    required this.autoSync,
    required this.syncIntervalMinutes,
    required this.syncOnWifiOnly,
    required this.backgroundSync,
    required this.syncBookmarks,
    required this.syncComments,
    required this.syncReadingProgress,
    required this.syncTags,
  });

  factory SyncSettings.fromJson(Map<String, dynamic> json) =>
      _$SyncSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SyncSettingsToJson(this);

  SyncSettings copyWith({
    bool? autoSync,
    int? syncIntervalMinutes,
    bool? syncOnWifiOnly,
    bool? backgroundSync,
    bool? syncBookmarks,
    bool? syncComments,
    bool? syncReadingProgress,
    bool? syncTags,
  }) {
    return SyncSettings(
      autoSync: autoSync ?? this.autoSync,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
      backgroundSync: backgroundSync ?? this.backgroundSync,
      syncBookmarks: syncBookmarks ?? this.syncBookmarks,
      syncComments: syncComments ?? this.syncComments,
      syncReadingProgress: syncReadingProgress ?? this.syncReadingProgress,
      syncTags: syncTags ?? this.syncTags,
    );
  }

  static const SyncSettings defaultSettings = SyncSettings(
    autoSync: true,
    syncIntervalMinutes: 15,
    syncOnWifiOnly: false,
    backgroundSync: true,
    syncBookmarks: true,
    syncComments: true,
    syncReadingProgress: true,
    syncTags: true,
  );
}

/// Cache-related settings
@JsonSerializable()
class CacheSettings {
  final int maxCacheSizeMB;
  final int maxThumbnailCacheSizeMB;
  final bool enablePagePreloading;
  final int preloadPageCount;
  final bool compressImages;
  final int imageQuality;
  final bool autoCleanup;
  final int cleanupIntervalDays;

  const CacheSettings({
    required this.maxCacheSizeMB,
    required this.maxThumbnailCacheSizeMB,
    required this.enablePagePreloading,
    required this.preloadPageCount,
    required this.compressImages,
    required this.imageQuality,
    required this.autoCleanup,
    required this.cleanupIntervalDays,
  });

  factory CacheSettings.fromJson(Map<String, dynamic> json) =>
      _$CacheSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$CacheSettingsToJson(this);

  CacheSettings copyWith({
    int? maxCacheSizeMB,
    int? maxThumbnailCacheSizeMB,
    bool? enablePagePreloading,
    int? preloadPageCount,
    bool? compressImages,
    int? imageQuality,
    bool? autoCleanup,
    int? cleanupIntervalDays,
  }) {
    return CacheSettings(
      maxCacheSizeMB: maxCacheSizeMB ?? this.maxCacheSizeMB,
      maxThumbnailCacheSizeMB:
          maxThumbnailCacheSizeMB ?? this.maxThumbnailCacheSizeMB,
      enablePagePreloading: enablePagePreloading ?? this.enablePagePreloading,
      preloadPageCount: preloadPageCount ?? this.preloadPageCount,
      compressImages: compressImages ?? this.compressImages,
      imageQuality: imageQuality ?? this.imageQuality,
      autoCleanup: autoCleanup ?? this.autoCleanup,
      cleanupIntervalDays: cleanupIntervalDays ?? this.cleanupIntervalDays,
    );
  }

  static const CacheSettings defaultSettings = CacheSettings(
    maxCacheSizeMB: 1024, // 1GB
    maxThumbnailCacheSizeMB: 256, // 256MB
    enablePagePreloading: true,
    preloadPageCount: 3,
    compressImages: true,
    imageQuality: 85,
    autoCleanup: true,
    cleanupIntervalDays: 7,
  );
}

/// Notification settings
@JsonSerializable()
class NotificationSettings {
  final bool enableNotifications;
  final bool syncCompleteNotifications;
  final bool scanCompleteNotifications;
  final bool errorNotifications;
  final bool backgroundSyncNotifications;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool enableQuietHours;

  const NotificationSettings({
    required this.enableNotifications,
    required this.syncCompleteNotifications,
    required this.scanCompleteNotifications,
    required this.errorNotifications,
    required this.backgroundSyncNotifications,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.enableQuietHours,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationSettingsToJson(this);

  NotificationSettings copyWith({
    bool? enableNotifications,
    bool? syncCompleteNotifications,
    bool? scanCompleteNotifications,
    bool? errorNotifications,
    bool? backgroundSyncNotifications,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? enableQuietHours,
  }) {
    return NotificationSettings(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      syncCompleteNotifications:
          syncCompleteNotifications ?? this.syncCompleteNotifications,
      scanCompleteNotifications:
          scanCompleteNotifications ?? this.scanCompleteNotifications,
      errorNotifications: errorNotifications ?? this.errorNotifications,
      backgroundSyncNotifications:
          backgroundSyncNotifications ?? this.backgroundSyncNotifications,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      enableQuietHours: enableQuietHours ?? this.enableQuietHours,
    );
  }

  static const NotificationSettings defaultSettings = NotificationSettings(
    enableNotifications: true,
    syncCompleteNotifications: true,
    scanCompleteNotifications: true,
    errorNotifications: true,
    backgroundSyncNotifications: false,
    quietHoursStart: '22:00',
    quietHoursEnd: '08:00',
    enableQuietHours: false,
  );
}

/// Accessibility settings
@JsonSerializable()
class AccessibilitySettings {
  final bool highContrast;
  final bool reduceAnimations;
  final bool largeText;
  final bool screenReaderSupport;
  final bool hapticFeedback;
  final bool soundEffects;

  const AccessibilitySettings({
    required this.highContrast,
    required this.reduceAnimations,
    required this.largeText,
    required this.screenReaderSupport,
    required this.hapticFeedback,
    required this.soundEffects,
  });

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) =>
      _$AccessibilitySettingsFromJson(json);

  Map<String, dynamic> toJson() => _$AccessibilitySettingsToJson(this);

  AccessibilitySettings copyWith({
    bool? highContrast,
    bool? reduceAnimations,
    bool? largeText,
    bool? screenReaderSupport,
    bool? hapticFeedback,
    bool? soundEffects,
  }) {
    return AccessibilitySettings(
      highContrast: highContrast ?? this.highContrast,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      largeText: largeText ?? this.largeText,
      screenReaderSupport: screenReaderSupport ?? this.screenReaderSupport,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      soundEffects: soundEffects ?? this.soundEffects,
    );
  }

  static const AccessibilitySettings defaultSettings = AccessibilitySettings(
    highContrast: false,
    reduceAnimations: false,
    largeText: false,
    screenReaderSupport: false,
    hapticFeedback: true,
    soundEffects: true,
  );
}

// Note: ThemeMode is now imported from Flutter Material library as material.ThemeMode
// DocumentViewMode and DocumentSortBy are imported from document_view_settings.dart