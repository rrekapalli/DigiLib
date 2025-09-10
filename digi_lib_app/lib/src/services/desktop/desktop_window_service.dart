import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';

/// Service for managing desktop window behavior and settings
class DesktopWindowService {
  static const String _windowStateKey = 'window_state';
  
  /// Initialize desktop window settings
  static Future<void> initialize() async {
    if (!_isDesktop) return;
    
    await windowManager.ensureInitialized();
    
    // Set minimum window size
    await windowManager.setMinimumSize(const Size(800, 600));
    
    // Restore previous window state or set default
    await _restoreWindowState();
    
    // Make window visible
    await windowManager.show();
    await windowManager.focus();
  }
  
  /// Save current window state for restoration
  static Future<void> saveWindowState() async {
    if (!_isDesktop) return;
    
    try {
      final bounds = await windowManager.getBounds();
      final isMaximized = await windowManager.isMaximized();
      final isFullScreen = await windowManager.isFullScreen();
      
      // Save to shared preferences or local storage
      // Implementation would depend on your storage service
      print('Saving window state: ${bounds.toString()}');
    } catch (e) {
      print('Error saving window state: $e');
    }
  }
  
  /// Restore window state from saved preferences
  static Future<void> _restoreWindowState() async {
    try {
      // Get screen size for bounds checking
      final primaryDisplay = await screenRetriever.getPrimaryDisplay();
      final screenSize = primaryDisplay.size;
      
      // Default window size (80% of screen)
      final defaultWidth = screenSize.width * 0.8;
      final defaultHeight = screenSize.height * 0.8;
      final defaultX = (screenSize.width - defaultWidth) / 2;
      final defaultY = (screenSize.height - defaultHeight) / 2;
      
      await windowManager.setBounds(Rect.fromLTWH(
        defaultX,
        defaultY,
        defaultWidth,
        defaultHeight,
      ));
      
      // TODO: Load saved state from preferences
      // For now, use default positioning
    } catch (e) {
      print('Error restoring window state: $e');
    }
  }
  
  /// Toggle fullscreen mode
  static Future<void> toggleFullscreen() async {
    if (!_isDesktop) return;
    
    final isFullScreen = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isFullScreen);
  }
  
  /// Minimize window
  static Future<void> minimize() async {
    if (!_isDesktop) return;
    await windowManager.minimize();
  }
  
  /// Maximize/restore window
  static Future<void> toggleMaximize() async {
    if (!_isDesktop) return;
    
    final isMaximized = await windowManager.isMaximized();
    if (isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }
  
  /// Close window with confirmation
  static Future<bool> requestClose() async {
    if (!_isDesktop) return true;
    
    // Save state before closing
    await saveWindowState();
    
    // TODO: Show confirmation dialog if there are unsaved changes
    return true;
  }
  
  /// Set window title
  static Future<void> setTitle(String title) async {
    if (!_isDesktop) return;
    await windowManager.setTitle(title);
  }
  
  /// Check if running on desktop platform
  static bool get _isDesktop {
    return !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  }
}

/// Window event listener for handling window lifecycle events
class DesktopWindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    final shouldClose = await DesktopWindowService.requestClose();
    if (shouldClose) {
      await windowManager.destroy();
    }
  }
  
  @override
  void onWindowResize() {
    // Save window state when resized
    DesktopWindowService.saveWindowState();
  }
  
  @override
  void onWindowMove() {
    // Save window state when moved
    DesktopWindowService.saveWindowState();
  }
  
  @override
  void onWindowMaximize() {
    DesktopWindowService.saveWindowState();
  }
  
  @override
  void onWindowUnmaximize() {
    DesktopWindowService.saveWindowState();
  }
}