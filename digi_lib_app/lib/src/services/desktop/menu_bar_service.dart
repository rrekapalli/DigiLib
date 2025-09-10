import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:menu_bar/menu_bar.dart';
import 'keyboard_shortcuts_service.dart';

/// Service for managing desktop application menu bar
class MenuBarService {
  static List<BarButton> _menuButtons = [];
  
  /// Initialize menu bar for desktop platforms
  static void initialize({
    VoidCallback? onNewLibrary,
    VoidCallback? onOpenFile,
    VoidCallback? onSettings,
    VoidCallback? onAbout,
    VoidCallback? onQuit,
    VoidCallback? onSearch,
    VoidCallback? onRefresh,
    VoidCallback? onToggleFullscreen,
    VoidCallback? onZoomIn,
    VoidCallback? onZoomOut,
    VoidCallback? onZoomReset,
    VoidCallback? onGoBack,
    VoidCallback? onGoForward,
  }) {
    if (!_isDesktop) return;
    
    _menuButtons = [
      // File Menu
      BarButton(
        text: const Text('File'),
        submenu: SubMenu(
          menuItems: [
            MenuButton(
              text: const Text('New Library'),
              shortcutText: KeyboardShortcutsService.getShortcutText('new_library'),
              onTap: onNewLibrary,
            ),
            MenuButton(
              text: const Text('Open File...'),
              shortcutText: 'Ctrl+O',
              onTap: onOpenFile,
            ),
            const MenuDivider(),
            MenuButton(
              text: const Text('Settings'),
              shortcutText: KeyboardShortcutsService.getShortcutText('settings'),
              onTap: onSettings,
            ),
            const MenuDivider(),
            MenuButton(
              text: Text(Platform.isMacOS ? 'Quit Digital Library' : 'Exit'),
              shortcutText: Platform.isMacOS ? '⌘Q' : 'Alt+F4',
              onTap: onQuit,
            ),
          ],
        ),
      ),
      
      // Edit Menu
      BarButton(
        text: const Text('Edit'),
        submenu: SubMenu(
          menuItems: [
            MenuButton(
              text: const Text('Search'),
              shortcutText: KeyboardShortcutsService.getShortcutText('search'),
              onTap: onSearch,
            ),
            const MenuDivider(),
            MenuButton(
              text: const Text('Refresh'),
              shortcutText: KeyboardShortcutsService.getShortcutText('refresh'),
              onTap: onRefresh,
            ),
          ],
        ),
      ),
      
      // View Menu
      BarButton(
        text: const Text('View'),
        submenu: SubMenu(
          menuItems: [
            MenuButton(
              text: const Text('Toggle Fullscreen'),
              shortcutText: KeyboardShortcutsService.getShortcutText('fullscreen'),
              onTap: onToggleFullscreen,
            ),
            const MenuDivider(),
            MenuButton(
              text: const Text('Zoom In'),
              shortcutText: KeyboardShortcutsService.getShortcutText('zoom_in'),
              onTap: onZoomIn,
            ),
            MenuButton(
              text: const Text('Zoom Out'),
              shortcutText: KeyboardShortcutsService.getShortcutText('zoom_out'),
              onTap: onZoomOut,
            ),
            MenuButton(
              text: const Text('Reset Zoom'),
              shortcutText: KeyboardShortcutsService.getShortcutText('zoom_reset'),
              onTap: onZoomReset,
            ),
          ],
        ),
      ),
      
      // Navigate Menu
      BarButton(
        text: const Text('Navigate'),
        submenu: SubMenu(
          menuItems: [
            MenuButton(
              text: const Text('Back'),
              shortcutText: KeyboardShortcutsService.getShortcutText('back'),
              onTap: onGoBack,
            ),
            MenuButton(
              text: const Text('Forward'),
              shortcutText: KeyboardShortcutsService.getShortcutText('forward'),
              onTap: onGoForward,
            ),
          ],
        ),
      ),
      
      // Help Menu
      BarButton(
        text: const Text('Help'),
        submenu: SubMenu(
          menuItems: [
            MenuButton(
              text: const Text('About Digital Library'),
              onTap: onAbout,
            ),
          ],
        ),
      ),
    ];
  }
  
  /// Get the configured menu buttons
  static List<BarButton> get menuButtons => _menuButtons;
  
  /// Update menu state (enable/disable items based on context)
  static void updateMenuState({
    bool canGoBack = false,
    bool canGoForward = false,
    bool hasDocument = false,
  }) {
    // This would update menu item states based on current context
    // Implementation depends on how menu_bar package handles state updates
  }
  
  /// Check if running on desktop platform
  static bool get _isDesktop {
    return !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  }
}