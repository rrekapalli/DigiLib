import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/app_settings.dart';
import '../services/settings_service.dart';
import '../services/secure_storage_service.dart';

/// Provider for settings service
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return SettingsService(secureStorage: secureStorage);
});

/// Provider for secure storage service
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider for app settings state
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return SettingsNotifier(settingsService);
});

/// Settings state notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsService _settingsService;

  SettingsNotifier(this._settingsService) : super(AppSettings.defaultSettings) {
    _initialize();
  }

  /// Initialize settings
  Future<void> _initialize() async {
    await _settingsService.initialize();
    state = _settingsService.currentSettings;
  }

  /// Update UI settings
  Future<void> updateUISettings(UISettings uiSettings) async {
    await _settingsService.updateUISettings(uiSettings);
    state = _settingsService.currentSettings;
  }

  /// Update sync settings
  Future<void> updateSyncSettings(SyncSettings syncSettings) async {
    await _settingsService.updateSyncSettings(syncSettings);
    state = _settingsService.currentSettings;
  }

  /// Update cache settings
  Future<void> updateCacheSettings(CacheSettings cacheSettings) async {
    await _settingsService.updateCacheSettings(cacheSettings);
    state = _settingsService.currentSettings;
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(NotificationSettings notificationSettings) async {
    await _settingsService.updateNotificationSettings(notificationSettings);
    state = _settingsService.currentSettings;
  }

  /// Update accessibility settings
  Future<void> updateAccessibilitySettings(AccessibilitySettings accessibilitySettings) async {
    await _settingsService.updateAccessibilitySettings(accessibilitySettings);
    state = _settingsService.currentSettings;
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    await _settingsService.resetToDefaults();
    state = _settingsService.currentSettings;
  }

  /// Export settings
  String exportSettings() {
    return _settingsService.exportSettings();
  }

  /// Import settings
  Future<void> importSettings(String settingsJson) async {
    await _settingsService.importSettings(settingsJson);
    state = _settingsService.currentSettings;
  }
}

/// Provider for theme mode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.ui.themeMode;
});

/// Provider for text scale factor
final textScaleFactorProvider = Provider<double>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.ui.textScaleFactor;
});

/// Provider for cache settings
final cacheSettingsProvider = Provider<CacheSettings>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.cache;
});

/// Provider for sync settings
final syncSettingsProvider = Provider<SyncSettings>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.sync;
});

/// Provider for notification settings
final notificationSettingsProvider = Provider<NotificationSettings>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.notifications;
});

/// Provider for accessibility settings
final accessibilitySettingsProvider = Provider<AccessibilitySettings>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.accessibility;
});