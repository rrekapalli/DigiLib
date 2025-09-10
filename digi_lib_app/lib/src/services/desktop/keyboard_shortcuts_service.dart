import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

/// Service for managing desktop keyboard shortcuts
class KeyboardShortcutsService {
  static final Map<String, HotKey> _registeredHotKeys = {};
  static final Map<String, VoidCallback> _shortcuts = {};
  
  /// Initialize keyboard shortcuts
  static Future<void> initialize() async {
    if (!_isDesktop) return;
    
    await hotKeyManager.unregisterAll();
    
    // Register global shortcuts
    await _registerGlobalShortcuts();
  }
  
  /// Register application-specific shortcuts
  static void registerShortcuts({
    VoidCallback? onNewLibrary,
    VoidCallback? onSearch,
    VoidCallback? onSettings,
    VoidCallback? onToggleFullscreen,
    VoidCallback? onRefresh,
    VoidCallback? onGoBack,
    VoidCallback? onGoForward,
    VoidCallback? onZoomIn,
    VoidCallback? onZoomOut,
    VoidCallback? onZoomReset,
  }) {
    _shortcuts.clear();
    
    if (onNewLibrary != null) _shortcuts['new_library'] = onNewLibrary;
    if (onSearch != null) _shortcuts['search'] = onSearch;
    if (onSettings != null) _shortcuts['settings'] = onSettings;
    if (onToggleFullscreen != null) _shortcuts['fullscreen'] = onToggleFullscreen;
    if (onRefresh != null) _shortcuts['refresh'] = onRefresh;
    if (onGoBack != null) _shortcuts['back'] = onGoBack;
    if (onGoForward != null) _shortcuts['forward'] = onGoForward;
    if (onZoomIn != null) _shortcuts['zoom_in'] = onZoomIn;
    if (onZoomOut != null) _shortcuts['zoom_out'] = onZoomOut;
    if (onZoomReset != null) _shortcuts['zoom_reset'] = onZoomReset;
  }
  
  /// Register global hotkeys
  static Future<void> _registerGlobalShortcuts() async {
    try {
      // Ctrl+N - New Library
      await _registerHotKey(
        'new_library',
        HotKey(
          key: PhysicalKeyboardKey.keyN,
          modifiers: [HotKeyModifier.control],
          scope: HotKeyScope.inapp,
        ),
      );
      
      // Ctrl+F - Search
      await _registerHotKey(
        'search',
        HotKey(
          key: PhysicalKeyboardKey.keyF,
          modifiers: [HotKeyModifier.control],
          scope: HotKeyScope.inapp,
        ),
      );
      
      // Ctrl+, - Settings (Ctrl+Comma)
      await _registerHotKey(
        'settings',
        HotKey(
          key: PhysicalKeyboardKey.comma,
          modifiers: [HotKeyModifier.control],
          scope: HotKeyScope.inapp,
        ),
      );
      
      // F11 - Toggle Fullscreen
      await _registerHotKey(
        'fullscreen',
        HotKey(
          key: PhysicalKeyboardKey.f11,
          scope: HotKeyScope.inapp,
        ),
      );
      
      // F5 - Refresh
      await _registerHotKey(
        'refresh',
        HotKey(
          key: PhysicalKeyboardKey.f5,
          scope: HotKeyScope.inapp,
        ),
      );
      
      // Alt+Left - Back
      await _registerHotKey(
        'back',
        HotKey(
          key: PhysicalKeyboardKey.arrowLeft,
          modifiers: [HotKeyModifier.alt],
          scope: HotKeyScope.inapp,
        ),
      );
      
      // Alt+Right - Forward
      await _registerHotKey(
        'forward',
        HotKey(
          key: PhysicalKeyboardKey.arrowRight,
          modifiers: [HotKeyModifier.alt],
          scope: HotKeyScope.inapp,
        ),
      );
      
      // Ctrl+Plus - Zoom In
      await _registerHotKey(
        'zoom_in',
        HotKey(
          key: PhysicalKeyboardKey.equal,
          modifiers: [HotKeyModifier.control],
          scope: HotKeyScope.inapp,
        ),
      );
      
      // Ctrl+Minus - Zoom Out
      await _registerHotKey(
        'zoom_out',
        HotKey(
          key: PhysicalKeyboardKey.minus,
          modifiers: [HotKeyModifier.control],
          scope: HotKeyScope.inapp,
        ),
      );
      
      // Ctrl+0 - Reset Zoom
      await _registerHotKey(
        'zoom_reset',
        HotKey(
          key: PhysicalKeyboardKey.digit0,
          modifiers: [HotKeyModifier.control],
          scope: HotKeyScope.inapp,
        ),
      );
      
    } catch (e) {
      debugPrint('Error registering hotkeys: $e');
    }
  }
  
  /// Register a single hotkey
  static Future<void> _registerHotKey(String id, HotKey hotKey) async {
    try {
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (hotKey) {
          final callback = _shortcuts[id];
          callback?.call();
        },
      );
      _registeredHotKeys[id] = hotKey;
    } catch (e) {
      debugPrint('Error registering hotkey $id: $e');
    }
  }
  
  /// Unregister all hotkeys
  static Future<void> dispose() async {
    if (!_isDesktop) return;
    
    try {
      await hotKeyManager.unregisterAll();
      _registeredHotKeys.clear();
      _shortcuts.clear();
    } catch (e) {
      debugPrint('Error disposing hotkeys: $e');
    }
  }
  
  /// Get keyboard shortcut text for display in UI
  static String getShortcutText(String action) {
    final hotKey = _registeredHotKeys[action];
    if (hotKey == null) return '';
    
    final modifiers = <String>[];
    if (hotKey.modifiers?.contains(HotKeyModifier.control) == true) {
      modifiers.add(Platform.isMacOS ? '⌘' : 'Ctrl');
    }
    if (hotKey.modifiers?.contains(HotKeyModifier.alt) == true) {
      modifiers.add(Platform.isMacOS ? '⌥' : 'Alt');
    }
    if (hotKey.modifiers?.contains(HotKeyModifier.shift) == true) {
      modifiers.add(Platform.isMacOS ? '⇧' : 'Shift');
    }
    
    String keyText = _getKeyText(hotKey.key);
    
    return modifiers.isEmpty ? keyText : '${modifiers.join('+')}+$keyText';
  }
  
  /// Convert KeyboardKey to display text
  static String _getKeyText(KeyboardKey keyCode) {
    // Convert the key to a string and extract the readable part
    final keyString = keyCode.toString();
    
    // Handle common keys
    if (keyString.contains('keyN')) return 'N';
    if (keyString.contains('keyF')) return 'F';
    if (keyString.contains('comma')) return ',';
    if (keyString.contains('f11')) return 'F11';
    if (keyString.contains('f5')) return 'F5';
    if (keyString.contains('arrowLeft')) return '←';
    if (keyString.contains('arrowRight')) return '→';
    if (keyString.contains('equal')) return '+';
    if (keyString.contains('minus')) return '-';
    if (keyString.contains('digit0')) return '0';
    
    // Default to the string representation
    return keyString;
  }
  
  /// Check if running on desktop platform
  static bool get _isDesktop {
    return !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  }
}