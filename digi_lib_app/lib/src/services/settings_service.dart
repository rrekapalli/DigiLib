import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/entities/app_settings.dart';
import 'secure_storage_service.dart';

/// Service for managing app settings and user preferences
class SettingsService {
  static const String _settingsKey = 'app_settings';
  
  final SecureStorageService _secureStorage;
  AppSettings _currentSettings = AppSettings.defaultSettings;
  
  SettingsService({
    required SecureStorageService secureStorage,
  }) : _secureStorage = secureStorage;

  /// Get current settings
  AppSettings get currentSettings => _currentSettings;

  /// Initialize settings service and load saved settings
  Future<void> initialize() async {
    try {
      final settingsJson = await _secureStorage.read(_settingsKey);
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _currentSettings = AppSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      // Use default settings if loading fails
      _currentSettings = AppSettings.defaultSettings;
    }
  }

  /// Save settings to secure storage
  Future<void> saveSettings(AppSettings settings) async {
    try {
      _currentSettings = settings;
      final settingsJson = jsonEncode(settings.toJson());
      await _secureStorage.write(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('Failed to save settings: $e');
      rethrow;
    }
  }

  /// Update UI settings
  Future<void> updateUISettings(UISettings uiSettings) async {
    final updatedSettings = _currentSettings.copyWith(ui: uiSettings);
    await saveSettings(updatedSettings);
  }

  /// Update sync settings
  Future<void> updateSyncSettings(SyncSettings syncSettings) async {
    final updatedSettings = _currentSettings.copyWith(sync: syncSettings);
    await saveSettings(updatedSettings);
  }

  /// Update cache settings
  Future<void> updateCacheSettings(CacheSettings cacheSettings) async {
    final updatedSettings = _currentSettings.copyWith(cache: cacheSettings);
    await saveSettings(updatedSettings);
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(NotificationSettings notificationSettings) async {
    final updatedSettings = _currentSettings.copyWith(notifications: notificationSettings);
    await saveSettings(updatedSettings);
  }

  /// Update accessibility settings
  Future<void> updateAccessibilitySettings(AccessibilitySettings accessibilitySettings) async {
    final updatedSettings = _currentSettings.copyWith(accessibility: accessibilitySettings);
    await saveSettings(updatedSettings);
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults() async {
    await saveSettings(AppSettings.defaultSettings);
  }

  /// Export settings as JSON string
  String exportSettings() {
    return jsonEncode(_currentSettings.toJson());
  }

  /// Import settings from JSON string
  Future<void> importSettings(String settingsJson) async {
    try {
      final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
      final settings = AppSettings.fromJson(settingsMap);
      await saveSettings(settings);
    } catch (e) {
      debugPrint('Failed to import settings: $e');
      rethrow;
    }
  }

  /// Get cache size in bytes
  int get maxCacheSizeBytes => _currentSettings.cache.maxCacheSizeMB * 1024 * 1024;

  /// Get thumbnail cache size in bytes
  int get maxThumbnailCacheSizeBytes => _currentSettings.cache.maxThumbnailCacheSizeMB * 1024 * 1024;

  /// Check if notifications are enabled
  bool get notificationsEnabled => _currentSettings.notifications.enableNotifications;

  /// Check if auto sync is enabled
  bool get autoSyncEnabled => _currentSettings.sync.autoSync;

  /// Get sync interval in milliseconds
  int get syncIntervalMs => _currentSettings.sync.syncIntervalMinutes * 60 * 1000;

  /// Check if background sync is enabled
  bool get backgroundSyncEnabled => _currentSettings.sync.backgroundSync;

  /// Check if sync should only happen on WiFi
  bool get syncOnWifiOnly => _currentSettings.sync.syncOnWifiOnly;
}