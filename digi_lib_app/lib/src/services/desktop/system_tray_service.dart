import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';

/// Service for managing system tray integration on desktop platforms
class SystemTrayService {
  static final SystemTray _systemTray = SystemTray();
  static bool _isInitialized = false;

  /// Initialize system tray
  static Future<void> initialize({
    VoidCallback? onShow,
    VoidCallback? onHide,
    VoidCallback? onQuit,
    VoidCallback? onNewLibrary,
    VoidCallback? onSearch,
  }) async {
    if (!_isDesktop || _isInitialized) return;

    try {
      // Initialize system tray with icon
      await _systemTray.initSystemTray(
        title: "Digital Library",
        iconPath: _getTrayIconPath(),
      );

      // Create context menu
      final Menu menu = Menu();

      await menu.buildFrom([
        MenuItemLabel(
          label: 'Show Digital Library',
          onClicked: (menuItem) => onShow?.call(),
        ),
        MenuItemLabel(
          label: 'Hide Digital Library',
          onClicked: (menuItem) => onHide?.call(),
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: 'New Library',
          onClicked: (menuItem) => onNewLibrary?.call(),
        ),
        MenuItemLabel(
          label: 'Search',
          onClicked: (menuItem) => onSearch?.call(),
        ),
        MenuSeparator(),
        MenuItemLabel(label: 'Quit', onClicked: (menuItem) => onQuit?.call()),
      ]);

      // Set context menu
      await _systemTray.setContextMenu(menu);

      // Handle tray icon clicks
      _systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          onShow?.call();
        } else if (eventName == kSystemTrayEventRightClick) {
          _systemTray.popUpContextMenu();
        }
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing system tray: $e');
    }
  }

  /// Update tray tooltip
  static Future<void> updateTooltip(String tooltip) async {
    if (!_isInitialized) return;

    try {
      await _systemTray.setToolTip(tooltip);
    } catch (e) {
      debugPrint('Error updating tray tooltip: $e');
    }
  }

  /// Show notification from system tray
  static Future<void> showNotification({
    required String title,
    required String message,
    String? iconPath,
  }) async {
    if (!_isInitialized) return;

    try {
      // Note: system_tray package may not support notifications directly
      // This would need to be implemented using flutter_local_notifications
      // or platform-specific notification APIs
      debugPrint('Tray notification: $title - $message');
    } catch (e) {
      debugPrint('Error showing tray notification: $e');
    }
  }

  /// Dispose system tray
  static Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await _systemTray.destroy();
      _isInitialized = false;
    } catch (e) {
      debugPrint('Error disposing system tray: $e');
    }
  }

  /// Get platform-specific tray icon path
  static String _getTrayIconPath() {
    if (Platform.isWindows) {
      return 'assets/icons/tray_icon.ico';
    } else if (Platform.isMacOS) {
      return 'assets/icons/tray_icon.png';
    } else if (Platform.isLinux) {
      return 'assets/icons/tray_icon.png';
    }
    return 'assets/icons/tray_icon.png';
  }

  /// Check if system tray is supported and initialized
  static bool get isAvailable => _isInitialized;

  /// Check if running on desktop platform
  static bool get _isDesktop {
    return !kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  }
}
