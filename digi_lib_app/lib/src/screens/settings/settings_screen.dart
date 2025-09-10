import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../models/entities/app_settings.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/settings_tile.dart';
import '../../widgets/cache_management_dialog.dart';
import '../../widgets/theme_selection_dialog.dart';
import '../../widgets/sync_interval_dialog.dart';
import '../../widgets/quiet_hours_dialog.dart';
import '../../widgets/text_scale_dialog.dart';
import '../../widgets/cache_size_dialog.dart';
import '../../widgets/settings_export_import_dialog.dart';
import 'account_security_screen.dart';

/// Main settings screen with all app preferences
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_import',
                child: ListTile(
                  leading: Icon(Icons.import_export),
                  title: Text('Export/Import'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.restore),
                  title: Text('Reset to Defaults'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // UI Settings Section
          SettingsSection(
            title: 'Appearance',
            icon: Icons.palette,
            children: [
              SettingsTile(
                title: 'Theme',
                subtitle: _getThemeModeText(settings.ui.themeMode),
                leading: const Icon(Icons.brightness_6),
                onTap: () => _showThemeDialog(context, ref),
              ),
              SettingsTile(
                title: 'Material You',
                subtitle: 'Use dynamic colors from wallpaper',
                leading: const Icon(Icons.color_lens),
                trailing: Switch(
                  value: settings.ui.useMaterialYou,
                  onChanged: (value) => _updateMaterialYou(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Text Size',
                subtitle: '${(settings.ui.textScaleFactor * 100).round()}%',
                leading: const Icon(Icons.text_fields),
                onTap: () => _showTextScaleDialog(context, ref),
              ),
              SettingsTile(
                title: 'Show Thumbnails',
                subtitle: 'Display document thumbnails in lists',
                leading: const Icon(Icons.image),
                trailing: Switch(
                  value: settings.ui.showThumbnails,
                  onChanged: (value) => _updateShowThumbnails(ref, value),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Sync Settings Section
          SettingsSection(
            title: 'Synchronization',
            icon: Icons.sync,
            children: [
              SettingsTile(
                title: 'Auto Sync',
                subtitle: 'Automatically sync data with server',
                leading: const Icon(Icons.sync),
                trailing: Switch(
                  value: settings.sync.autoSync,
                  onChanged: (value) => _updateAutoSync(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Sync Interval',
                subtitle: '${settings.sync.syncIntervalMinutes} minutes',
                leading: const Icon(Icons.schedule),
                onTap: settings.sync.autoSync
                    ? () => _showSyncIntervalDialog(context, ref)
                    : null,
                enabled: settings.sync.autoSync,
              ),
              SettingsTile(
                title: 'WiFi Only',
                subtitle: 'Only sync when connected to WiFi',
                leading: const Icon(Icons.wifi),
                trailing: Switch(
                  value: settings.sync.syncOnWifiOnly,
                  onChanged: (value) => _updateSyncOnWifiOnly(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Background Sync',
                subtitle: 'Sync data in the background',
                leading: const Icon(Icons.cloud_sync),
                trailing: Switch(
                  value: settings.sync.backgroundSync,
                  onChanged: (value) => _updateBackgroundSync(ref, value),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Cache Settings Section
          SettingsSection(
            title: 'Storage & Cache',
            icon: Icons.storage,
            children: [
              SettingsTile(
                title: 'Cache Size Limit',
                subtitle: '${settings.cache.maxCacheSizeMB} MB',
                leading: const Icon(Icons.folder),
                onTap: () => _showCacheSizeDialog(context, ref),
              ),
              SettingsTile(
                title: 'Thumbnail Cache',
                subtitle: '${settings.cache.maxThumbnailCacheSizeMB} MB',
                leading: const Icon(Icons.image),
                onTap: () => _showThumbnailCacheSizeDialog(context, ref),
              ),
              SettingsTile(
                title: 'Page Preloading',
                subtitle: 'Preload ${settings.cache.preloadPageCount} pages ahead',
                leading: const Icon(Icons.preview),
                trailing: Switch(
                  value: settings.cache.enablePagePreloading,
                  onChanged: (value) => _updatePagePreloading(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Auto Cleanup',
                subtitle: 'Clean cache every ${settings.cache.cleanupIntervalDays} days',
                leading: const Icon(Icons.cleaning_services),
                trailing: Switch(
                  value: settings.cache.autoCleanup,
                  onChanged: (value) => _updateAutoCleanup(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Manage Cache',
                subtitle: 'View and clear cached data',
                leading: const Icon(Icons.clear_all),
                onTap: () => _showCacheManagementDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Notification Settings Section
          SettingsSection(
            title: 'Notifications',
            icon: Icons.notifications,
            children: [
              SettingsTile(
                title: 'Enable Notifications',
                subtitle: 'Receive app notifications',
                leading: const Icon(Icons.notifications),
                trailing: Switch(
                  value: settings.notifications.enableNotifications,
                  onChanged: (value) => _updateNotificationsEnabled(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Sync Complete',
                subtitle: 'Notify when sync completes',
                leading: const Icon(Icons.sync_alt),
                trailing: Switch(
                  value: settings.notifications.syncCompleteNotifications,
                  onChanged: settings.notifications.enableNotifications
                      ? (value) => _updateSyncCompleteNotifications(ref, value)
                      : null,
                ),
                enabled: settings.notifications.enableNotifications,
              ),
              SettingsTile(
                title: 'Scan Complete',
                subtitle: 'Notify when library scan completes',
                leading: const Icon(Icons.scanner),
                trailing: Switch(
                  value: settings.notifications.scanCompleteNotifications,
                  onChanged: settings.notifications.enableNotifications
                      ? (value) => _updateScanCompleteNotifications(ref, value)
                      : null,
                ),
                enabled: settings.notifications.enableNotifications,
              ),
              SettingsTile(
                title: 'Quiet Hours',
                subtitle: settings.notifications.enableQuietHours
                    ? '${settings.notifications.quietHoursStart} - ${settings.notifications.quietHoursEnd}'
                    : 'Disabled',
                leading: const Icon(Icons.bedtime),
                onTap: settings.notifications.enableNotifications
                    ? () => _showQuietHoursDialog(context, ref)
                    : null,
                enabled: settings.notifications.enableNotifications,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Accessibility Settings Section
          SettingsSection(
            title: 'Accessibility',
            icon: Icons.accessibility,
            children: [
              SettingsTile(
                title: 'High Contrast',
                subtitle: 'Increase contrast for better visibility',
                leading: const Icon(Icons.contrast),
                trailing: Switch(
                  value: settings.accessibility.highContrast,
                  onChanged: (value) => _updateHighContrast(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Reduce Animations',
                subtitle: 'Minimize motion and animations',
                leading: const Icon(Icons.animation),
                trailing: Switch(
                  value: settings.accessibility.reduceAnimations,
                  onChanged: (value) => _updateReduceAnimations(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Haptic Feedback',
                subtitle: 'Vibration feedback for interactions',
                leading: const Icon(Icons.vibration),
                trailing: Switch(
                  value: settings.accessibility.hapticFeedback,
                  onChanged: (value) => _updateHapticFeedback(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Sound Effects',
                subtitle: 'Audio feedback for interactions',
                leading: const Icon(Icons.volume_up),
                trailing: Switch(
                  value: settings.accessibility.soundEffects,
                  onChanged: (value) => _updateSoundEffects(ref, value),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Account & Security Section
          SettingsSection(
            title: 'Account & Security',
            icon: Icons.account_circle,
            children: [
              SettingsTile(
                title: 'Account & Security',
                subtitle: 'Manage your account, security, and privacy settings',
                leading: const Icon(Icons.security),
                onTap: () => _navigateToAccountSecurity(context),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'export_import':
        _showExportImportDialog(context, ref);
        break;
      case 'reset':
        _showResetConfirmation(context, ref);
        break;
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ThemeSelectionDialog(
        currentTheme: ref.read(settingsProvider).ui.themeMode,
        onThemeChanged: (theme) => _updateThemeMode(ref, theme),
      ),
    );
  }

  void _showTextScaleDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => TextScaleDialog(
        currentScale: ref.read(settingsProvider).ui.textScaleFactor,
        onScaleChanged: (scale) => _updateTextScale(ref, scale),
      ),
    );
  }

  void _showSyncIntervalDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => SyncIntervalDialog(
        currentInterval: ref.read(settingsProvider).sync.syncIntervalMinutes,
        onIntervalChanged: (interval) => _updateSyncInterval(ref, interval),
      ),
    );
  }

  void _showCacheSizeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CacheSizeDialog(
        currentSize: ref.read(settingsProvider).cache.maxCacheSizeMB,
        title: 'Cache Size Limit',
        onSizeChanged: (size) => _updateCacheSize(ref, size),
      ),
    );
  }

  void _showThumbnailCacheSizeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CacheSizeDialog(
        currentSize: ref.read(settingsProvider).cache.maxThumbnailCacheSizeMB,
        title: 'Thumbnail Cache Size',
        onSizeChanged: (size) => _updateThumbnailCacheSize(ref, size),
      ),
    );
  }

  void _showQuietHoursDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => QuietHoursDialog(
        currentSettings: ref.read(settingsProvider).notifications,
        onSettingsChanged: (settings) => _updateQuietHours(ref, settings),
      ),
    );
  }

  void _showCacheManagementDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const CacheManagementDialog(),
    );
  }

  void _showExportImportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => SettingsExportImportDialog(
        onExport: () => ref.read(settingsProvider.notifier).exportSettings(),
        onImport: (json) => ref.read(settingsProvider.notifier).importSettings(json),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(settingsProvider.notifier).resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // Update methods
  void _updateThemeMode(WidgetRef ref, ThemeMode themeMode) {
    final currentSettings = ref.read(settingsProvider);
    final updatedUI = currentSettings.ui.copyWith(themeMode: themeMode);
    ref.read(settingsProvider.notifier).updateUISettings(updatedUI);
  }

  void _updateMaterialYou(WidgetRef ref, bool value) {
    final currentSettings = ref.read(settingsProvider);
    final updatedUI = currentSettings.ui.copyWith(useMaterialYou: value);
    ref.read(settingsProvider.notifier).updateUISettings(updatedUI);
  }

  void _updateTextScale(WidgetRef ref, double scale) {
    final currentSettings = ref.read(settingsProvider);
    final updatedUI = currentSettings.ui.copyWith(textScaleFactor: scale);
    ref.read(settingsProvider.notifier).updateUISettings(updatedUI);
  }

  void _updateShowThumbnails(WidgetRef ref, bool value) {
    final currentSettings = ref.read(settingsProvider);
    final updatedUI = currentSettings.ui.copyWith(showThumbnails: value);
    ref.read(settingsProvider.notifier).updateUISettings(updatedUI);
  }

  void _updateAutoSync(WidgetRef ref, bool value) {
    final currentSettings = ref.read(settingsProvider);
    final updatedSync = currentSettings.sync.copyWith(autoSync: value);
    ref.read(settingsProvider.notifier).updateSyncSettings(updatedSync);
  }

  void _updateSyncInterval(WidgetRef ref, int interval) {
    final currentSettings = ref.read(settingsProvider);
    final updatedSync = currentSettings.sync.copyWith(syncIntervalMinutes: interval);
    ref.read(settingsProvider.notifier).updateSyncSettings(updatedSync);
  }

  void _updateSyncOnWifiOnly(WidgetRef ref, bool value) {
    final currentSettings = ref.read(settingsProvider);
    final updatedSync = currentSettings.sync.copyWith(syncOnWifiOnly: value);
    ref.read(settingsProvider.notifier).updateSyncSettings(updatedSync);
  }

  void _updateBackgroundSync(WidgetRef ref, bool value) {
    final currentSettings = ref.read(settingsProvider);
    final updatedSync = currentSettings.sync.copyWith(backgroundSync: value);
    ref.read(settingsProvider.notifier).updateSyncSettings(updatedSync);
  }

  void _updateCacheSize(WidgetRef ref, int size) {
    final currentSettings = ref.read(settingsProvider);
    final updatedCache = currentSettings.cache.copyWith(maxCacheSizeMB: size);
    ref.read(settingsProvider.notifier).updateCacheSettings(updatedCache);
  }

  void _updateThumbnailCacheSize(WidgetRef ref, int size) {
    final currentSettings = ref.read(settingsProvider);
    final updatedCache = currentSettings.cache.copyWith(maxThumbnailCacheSizeMB: size);
    ref.read(settingsProvider.notifier).updateCacheSettings(updatedCache);
  }

  void _updatePagePreloading(WidgetRef ref, bool value) {
    final currentSettings = ref.read(settingsProvider);
    final updatedCache = currentSettings.cache.copyWith(enablePagePreloading: value);
    ref.read(settingsProvider.notifier).updateCacheSettings(updatedCache);
  }

  void _updateAutoCleanup(WidgetRef ref, bool value) {
    final currentSettings = ref.read(settingsProvider);
    final updatedCache = currentSettings.cache.copyWith(autoCleanup: value);
    ref.read(settingsProvider.notifier).updateCacheSettings(updatedCache);
  }

  void _updateNotificationsEnabled(WidgetRef ref, bool value) {
    final currentSettings = ref.read(settingsProvider);
    final updatedNotifications = currentSettings.notifications.copyWith(enableNotifications: value);
    ref.read(settingsProvider.notifier).updateNotificationSettings(updatedNotifications);
  }

  void _updateSyncCompleteNotifications(WidgetRef ref, bool value) {
    final currentSettings = ref.read(settingsProvider);
    final updatedNotifications = currentSettings.notifications.copyWith(syncCompleteNotifications: value);
    ref.read(settingsProvider.notifier).updateNotificationSettings(updatedNotifications);
  }

  void _updateScanCompleteNotifications(WidgetRef ref, bool value) {
    final currentSettings = ref.read(settingsProvider);
    final updatedNotifications = currentSettings.notifications.copyWith(scanCompleteNotifications: value);
    ref.read(settingsProvider.notifier).updateNotificationSettings(updatedNotifications);
  }

  void _updateQuietHours(WidgetRef ref, NotificationSettings settings) {
    ref.read(settingsProvider.notifier).updateNotificationSettings(settings);
  }

  void _updateHighContrast(WidgetRef ref, bool value) {
    final currentSettings = ref.read(settingsProvider);
    final updatedAccessibility = currentSettings.accessibility.copyWith(highContrast: value);
    ref.read(settingsProvider.notifier).updateAccessibilitySettings(updatedAccessibility);
  }

  void _updateReduceAnimations(WidgetRef ref, bool value) {
    final currentSettings = ref.read(settingsProvider);
    final updatedAccessibility = currentSettings.accessibility.copyWith(reduceAnimations: value);
    ref.read(settingsProvider.notifier).updateAccessibilitySettings(updatedAccessibility);
  }

  void _updateHapticFeedback(WidgetRef ref, bool value) {
    final currentSettings = ref.read(settingsProvider);
    final updatedAccessibility = currentSettings.accessibility.copyWith(hapticFeedback: value);
    ref.read(settingsProvider.notifier).updateAccessibilitySettings(updatedAccessibility);
  }

  void _updateSoundEffects(WidgetRef ref, bool value) {
    final currentSettings = ref.read(settingsProvider);
    final updatedAccessibility = currentSettings.accessibility.copyWith(soundEffects: value);
    ref.read(settingsProvider.notifier).updateAccessibilitySettings(updatedAccessibility);
  }

  void _navigateToAccountSecurity(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AccountSecurityScreen(),
      ),
    );
  }
}