import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'desktop_window_service.dart';
import 'keyboard_shortcuts_service.dart';
import 'menu_bar_service.dart';
import 'system_tray_service.dart';
import 'auto_updater_service.dart';
import 'file_system_service.dart';

/// Main service for coordinating all desktop-specific integrations
class DesktopIntegrationService {
  static bool _isInitialized = false;
  static final Map<String, VoidCallback> _callbacks = {};

  /// Initialize all desktop services
  static Future<void> initialize({
    // Window management callbacks
    VoidCallback? onWindowShow,
    VoidCallback? onWindowHide,
    VoidCallback? onWindowClose,

    // Application callbacks
    VoidCallback? onNewLibrary,
    VoidCallback? onOpenFile,
    VoidCallback? onSearch,
    VoidCallback? onSettings,
    VoidCallback? onAbout,
    VoidCallback? onQuit,
    VoidCallback? onRefresh,

    // Navigation callbacks
    VoidCallback? onGoBack,
    VoidCallback? onGoForward,

    // View callbacks
    VoidCallback? onToggleFullscreen,
    VoidCallback? onZoomIn,
    VoidCallback? onZoomOut,
    VoidCallback? onZoomReset,

    // Update configuration
    String? updateUrl,
    bool enableAutoUpdates = true,
  }) async {
    if (!_isDesktop || _isInitialized) return;

    try {
      // Store callbacks for later use
      _callbacks.addAll({
        'window_show': onWindowShow ?? () {},
        'window_hide': onWindowHide ?? () {},
        'window_close': onWindowClose ?? () {},
        'new_library': onNewLibrary ?? () {},
        'open_file': onOpenFile ?? () {},
        'search': onSearch ?? () {},
        'settings': onSettings ?? () {},
        'about': onAbout ?? () {},
        'quit': onQuit ?? () {},
        'refresh': onRefresh ?? () {},
        'go_back': onGoBack ?? () {},
        'go_forward': onGoForward ?? () {},
        'toggle_fullscreen': onToggleFullscreen ?? () {},
        'zoom_in': onZoomIn ?? () {},
        'zoom_out': onZoomOut ?? () {},
        'zoom_reset': onZoomReset ?? () {},
      });

      // Initialize window management
      await DesktopWindowService.initialize();

      // Initialize keyboard shortcuts
      await KeyboardShortcutsService.initialize();
      KeyboardShortcutsService.registerShortcuts(
        onNewLibrary: _callbacks['new_library'],
        onSearch: _callbacks['search'],
        onSettings: _callbacks['settings'],
        onToggleFullscreen: _callbacks['toggle_fullscreen'],
        onRefresh: _callbacks['refresh'],
        onGoBack: _callbacks['go_back'],
        onGoForward: _callbacks['go_forward'],
        onZoomIn: _callbacks['zoom_in'],
        onZoomOut: _callbacks['zoom_out'],
        onZoomReset: _callbacks['zoom_reset'],
      );

      // Initialize menu bar
      MenuBarService.initialize(
        onNewLibrary: _callbacks['new_library'],
        onOpenFile: _callbacks['open_file'],
        onSettings: _callbacks['settings'],
        onAbout: _callbacks['about'],
        onQuit: _callbacks['quit'],
        onSearch: _callbacks['search'],
        onRefresh: _callbacks['refresh'],
        onToggleFullscreen: _callbacks['toggle_fullscreen'],
        onZoomIn: _callbacks['zoom_in'],
        onZoomOut: _callbacks['zoom_out'],
        onZoomReset: _callbacks['zoom_reset'],
        onGoBack: _callbacks['go_back'],
        onGoForward: _callbacks['go_forward'],
      );

      // Initialize system tray
      await SystemTrayService.initialize(
        onShow: _callbacks['window_show'],
        onHide: _callbacks['window_hide'],
        onQuit: _callbacks['quit'],
        onNewLibrary: _callbacks['new_library'],
        onSearch: _callbacks['search'],
      );

      // Initialize auto updater if enabled and URL provided
      if (enableAutoUpdates && updateUrl != null) {
        await AutoUpdaterService.initialize(
          updateUrl: updateUrl,
          checkOnStartup: true,
        );

        AutoUpdaterService.setUpdateEventHandlers(
          onUpdateAvailable: (version, releaseNotes) {
            _showUpdateNotification(version, releaseNotes);
          },
          onUpdateError: (error) {
            debugPrint('Update error: $error');
          },
        );
      }

      _isInitialized = true;
      debugPrint('Desktop integration services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing desktop services: $e');
    }
  }

  /// Show update notification
  static void _showUpdateNotification(String version, String? releaseNotes) {
    SystemTrayService.showNotification(
      title: 'Update Available',
      message: 'Version $version is available for download',
    );
  }

  /// Handle application lifecycle events
  static Future<void> handleAppLifecycle(AppLifecycleState state) async {
    if (!_isInitialized) return;

    switch (state) {
      case AppLifecycleState.paused:
        await DesktopWindowService.saveWindowState();
        break;
      case AppLifecycleState.resumed:
        // Restore any needed state
        break;
      case AppLifecycleState.detached:
        await dispose();
        break;
      default:
        break;
    }
  }

  /// Update menu state based on application context
  static void updateMenuState({
    bool canGoBack = false,
    bool canGoForward = false,
    bool hasDocument = false,
  }) {
    if (!_isInitialized) return;

    MenuBarService.updateMenuState(
      canGoBack: canGoBack,
      canGoForward: canGoForward,
      hasDocument: hasDocument,
    );
  }

  /// Set window title
  static Future<void> setWindowTitle(String title) async {
    if (!_isInitialized) return;

    await DesktopWindowService.setTitle(title);
  }

  /// Show system tray notification
  static Future<void> showNotification({
    required String title,
    required String message,
  }) async {
    if (!_isInitialized) return;

    await SystemTrayService.showNotification(title: title, message: message);
  }

  /// Check for updates manually
  static Future<void> checkForUpdates() async {
    if (!_isInitialized) return;

    await AutoUpdaterService.checkForUpdates();
  }

  /// Handle file drops from desktop
  static void handleFilesDrop(List<String> files) {
    if (!_isInitialized) return;

    // Filter for supported document types
    final supportedFiles = files.where((file) {
      final extension = file.toLowerCase();
      return FileSystemService.supportedDocumentExtensions.any(
        (ext) => extension.endsWith(ext),
      );
    }).toList();

    if (supportedFiles.isNotEmpty) {
      // Handle dropped files (e.g., add to library, open for reading)
      debugPrint('Dropped ${supportedFiles.length} supported files');
      // Implementation would depend on your app's file handling logic
    }
  }

  /// Get desktop-specific keyboard shortcuts for display
  static Map<String, String> getKeyboardShortcuts() {
    if (!_isInitialized) return {};

    return {
      'New Library': KeyboardShortcutsService.getShortcutText('new_library'),
      'Search': KeyboardShortcutsService.getShortcutText('search'),
      'Settings': KeyboardShortcutsService.getShortcutText('settings'),
      'Fullscreen': KeyboardShortcutsService.getShortcutText('fullscreen'),
      'Refresh': KeyboardShortcutsService.getShortcutText('refresh'),
      'Back': KeyboardShortcutsService.getShortcutText('back'),
      'Forward': KeyboardShortcutsService.getShortcutText('forward'),
      'Zoom In': KeyboardShortcutsService.getShortcutText('zoom_in'),
      'Zoom Out': KeyboardShortcutsService.getShortcutText('zoom_out'),
      'Reset Zoom': KeyboardShortcutsService.getShortcutText('zoom_reset'),
    };
  }

  /// Dispose all desktop services
  static Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await KeyboardShortcutsService.dispose();
      await SystemTrayService.dispose();
      await DesktopWindowService.saveWindowState();

      _callbacks.clear();
      _isInitialized = false;

      debugPrint('Desktop integration services disposed');
    } catch (e) {
      debugPrint('Error disposing desktop services: $e');
    }
  }

  /// Check if desktop services are available
  static bool get isAvailable => _isInitialized;

  /// Check if running on desktop platform
  static bool get _isDesktop {
    return !kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  }
}
