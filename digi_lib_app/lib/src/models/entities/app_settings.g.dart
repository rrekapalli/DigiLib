// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => AppSettings(
      ui: UISettings.fromJson(json['ui'] as Map<String, dynamic>),
      sync: SyncSettings.fromJson(json['sync'] as Map<String, dynamic>),
      cache: CacheSettings.fromJson(json['cache'] as Map<String, dynamic>),
      notifications: NotificationSettings.fromJson(
          json['notifications'] as Map<String, dynamic>),
      accessibility: AccessibilitySettings.fromJson(
          json['accessibility'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppSettingsToJson(AppSettings instance) =>
    <String, dynamic>{
      'ui': instance.ui,
      'sync': instance.sync,
      'cache': instance.cache,
      'notifications': instance.notifications,
      'accessibility': instance.accessibility,
    };

UISettings _$UISettingsFromJson(Map<String, dynamic> json) => UISettings(
      themeMode: $enumDecode(_$ThemeModeEnumMap, json['themeMode']),
      useMaterialYou: json['useMaterialYou'] as bool,
      textScaleFactor: (json['textScaleFactor'] as num).toDouble(),
      showThumbnails: json['showThumbnails'] as bool,
      defaultViewMode:
          $enumDecode(_$DocumentViewModeEnumMap, json['defaultViewMode']),
      defaultSortOrder:
          $enumDecode(_$DocumentSortByEnumMap, json['defaultSortOrder']),
    );

Map<String, dynamic> _$UISettingsToJson(UISettings instance) =>
    <String, dynamic>{
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
      'useMaterialYou': instance.useMaterialYou,
      'textScaleFactor': instance.textScaleFactor,
      'showThumbnails': instance.showThumbnails,
      'defaultViewMode': _$DocumentViewModeEnumMap[instance.defaultViewMode]!,
      'defaultSortOrder': _$DocumentSortByEnumMap[instance.defaultSortOrder]!,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};

const _$DocumentViewModeEnumMap = {
  DocumentViewMode.list: 'list',
  DocumentViewMode.grid: 'grid',
};

const _$DocumentSortByEnumMap = {
  DocumentSortBy.name: 'name',
  DocumentSortBy.author: 'author',
  DocumentSortBy.dateCreated: 'dateCreated',
  DocumentSortBy.dateModified: 'dateModified',
  DocumentSortBy.size: 'size',
  DocumentSortBy.pageCount: 'pageCount',
};

SyncSettings _$SyncSettingsFromJson(Map<String, dynamic> json) => SyncSettings(
      autoSync: json['autoSync'] as bool,
      syncIntervalMinutes: (json['syncIntervalMinutes'] as num).toInt(),
      syncOnWifiOnly: json['syncOnWifiOnly'] as bool,
      backgroundSync: json['backgroundSync'] as bool,
      syncBookmarks: json['syncBookmarks'] as bool,
      syncComments: json['syncComments'] as bool,
      syncReadingProgress: json['syncReadingProgress'] as bool,
      syncTags: json['syncTags'] as bool,
    );

Map<String, dynamic> _$SyncSettingsToJson(SyncSettings instance) =>
    <String, dynamic>{
      'autoSync': instance.autoSync,
      'syncIntervalMinutes': instance.syncIntervalMinutes,
      'syncOnWifiOnly': instance.syncOnWifiOnly,
      'backgroundSync': instance.backgroundSync,
      'syncBookmarks': instance.syncBookmarks,
      'syncComments': instance.syncComments,
      'syncReadingProgress': instance.syncReadingProgress,
      'syncTags': instance.syncTags,
    };

CacheSettings _$CacheSettingsFromJson(Map<String, dynamic> json) =>
    CacheSettings(
      maxCacheSizeMB: (json['maxCacheSizeMB'] as num).toInt(),
      maxThumbnailCacheSizeMB: (json['maxThumbnailCacheSizeMB'] as num).toInt(),
      enablePagePreloading: json['enablePagePreloading'] as bool,
      preloadPageCount: (json['preloadPageCount'] as num).toInt(),
      compressImages: json['compressImages'] as bool,
      imageQuality: (json['imageQuality'] as num).toInt(),
      autoCleanup: json['autoCleanup'] as bool,
      cleanupIntervalDays: (json['cleanupIntervalDays'] as num).toInt(),
    );

Map<String, dynamic> _$CacheSettingsToJson(CacheSettings instance) =>
    <String, dynamic>{
      'maxCacheSizeMB': instance.maxCacheSizeMB,
      'maxThumbnailCacheSizeMB': instance.maxThumbnailCacheSizeMB,
      'enablePagePreloading': instance.enablePagePreloading,
      'preloadPageCount': instance.preloadPageCount,
      'compressImages': instance.compressImages,
      'imageQuality': instance.imageQuality,
      'autoCleanup': instance.autoCleanup,
      'cleanupIntervalDays': instance.cleanupIntervalDays,
    };

NotificationSettings _$NotificationSettingsFromJson(
        Map<String, dynamic> json) =>
    NotificationSettings(
      enableNotifications: json['enableNotifications'] as bool,
      syncCompleteNotifications: json['syncCompleteNotifications'] as bool,
      scanCompleteNotifications: json['scanCompleteNotifications'] as bool,
      errorNotifications: json['errorNotifications'] as bool,
      backgroundSyncNotifications: json['backgroundSyncNotifications'] as bool,
      quietHoursStart: json['quietHoursStart'] as String,
      quietHoursEnd: json['quietHoursEnd'] as String,
      enableQuietHours: json['enableQuietHours'] as bool,
    );

Map<String, dynamic> _$NotificationSettingsToJson(
        NotificationSettings instance) =>
    <String, dynamic>{
      'enableNotifications': instance.enableNotifications,
      'syncCompleteNotifications': instance.syncCompleteNotifications,
      'scanCompleteNotifications': instance.scanCompleteNotifications,
      'errorNotifications': instance.errorNotifications,
      'backgroundSyncNotifications': instance.backgroundSyncNotifications,
      'quietHoursStart': instance.quietHoursStart,
      'quietHoursEnd': instance.quietHoursEnd,
      'enableQuietHours': instance.enableQuietHours,
    };

AccessibilitySettings _$AccessibilitySettingsFromJson(
        Map<String, dynamic> json) =>
    AccessibilitySettings(
      highContrast: json['highContrast'] as bool,
      reduceAnimations: json['reduceAnimations'] as bool,
      largeText: json['largeText'] as bool,
      screenReaderSupport: json['screenReaderSupport'] as bool,
      hapticFeedback: json['hapticFeedback'] as bool,
      soundEffects: json['soundEffects'] as bool,
    );

Map<String, dynamic> _$AccessibilitySettingsToJson(
        AccessibilitySettings instance) =>
    <String, dynamic>{
      'highContrast': instance.highContrast,
      'reduceAnimations': instance.reduceAnimations,
      'largeText': instance.largeText,
      'screenReaderSupport': instance.screenReaderSupport,
      'hapticFeedback': instance.hapticFeedback,
      'soundEffects': instance.soundEffects,
    };
