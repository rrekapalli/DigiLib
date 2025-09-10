import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_drop/desktop_drop.dart';

/// Service for desktop-specific UI patterns and behaviors
class DesktopUIService {
  /// Check if current platform supports desktop UI patterns
  static bool get isDesktop {
    return !kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  }

  /// Get platform-specific window decorations
  static SystemUiOverlayStyle getWindowDecorations() {
    if (!isDesktop) return SystemUiOverlayStyle.dark;

    if (Platform.isWindows) {
      return const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarColor: Colors.transparent,
      );
    } else if (Platform.isMacOS) {
      return const SystemUiOverlayStyle(statusBarBrightness: Brightness.light);
    } else {
      // Linux
      return const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
      );
    }
  }

  /// Get desktop-appropriate spacing and sizing
  static EdgeInsets getDesktopPadding() {
    return const EdgeInsets.all(16.0);
  }

  /// Get desktop-appropriate button size
  static Size getDesktopButtonSize() {
    return const Size(120, 36);
  }

  /// Get desktop-appropriate icon size
  static double getDesktopIconSize() {
    return 20.0;
  }

  /// Create desktop-style context menu
  static void showDesktopContextMenu(
    BuildContext context,
    Offset position,
    List<PopupMenuEntry> items,
  ) {
    if (!isDesktop) return;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items,
      elevation: 8.0,
    );
  }

  /// Create desktop-style tooltip
  static Widget createDesktopTooltip({
    required String message,
    required Widget child,
    String? shortcut,
  }) {
    if (!isDesktop) return child;

    final tooltipMessage = shortcut != null ? '$message ($shortcut)' : message;

    return Tooltip(
      message: tooltipMessage,
      waitDuration: const Duration(milliseconds: 500),
      showDuration: const Duration(seconds: 3),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      child: child,
    );
  }

  /// Create desktop-style drag and drop area
  static Widget createDropArea({
    required Widget child,
    required Function(List<String> files) onFilesDropped,
    String? hoverText,
  }) {
    if (!isDesktop) return child;

    return DropTarget(
      onDragDone: (detail) {
        final files = detail.files
            .where((file) => file.path.isNotEmpty)
            .map((file) => file.path)
            .toList();
        if (files.isNotEmpty) {
          onFilesDropped(files);
        }
      },
      child: child,
    );
  }

  /// Create desktop-style resizable panels
  static Widget createResizablePanel({
    required Widget child,
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  }) {
    if (!isDesktop) return child;

    return Container(
      constraints: BoxConstraints(
        minWidth: minWidth ?? 200,
        maxWidth: maxWidth ?? double.infinity,
        minHeight: minHeight ?? 100,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: child,
    );
  }

  /// Get desktop-appropriate scroll behavior
  static ScrollBehavior getDesktopScrollBehavior() {
    return const MaterialScrollBehavior().copyWith(
      dragDevices: {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      },
      scrollbars: true,
    );
  }

  /// Create desktop-style toolbar
  static PreferredSizeWidget createDesktopToolbar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool showBackButton = false,
  }) {
    return AppBar(
      title: Text(title),
      leading: leading,
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black87,
      toolbarHeight: 48,
    );
  }

  /// Create desktop-style status bar
  static Widget createDesktopStatusBar({required List<Widget> items}) {
    if (!isDesktop) return const SizedBox.shrink();

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: const Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: item,
              ),
            )
            .toList(),
      ),
    );
  }

  /// Create desktop-style sidebar
  static Widget createDesktopSidebar({
    required List<Widget> items,
    double width = 250,
    bool isCollapsed = false,
  }) {
    if (!isDesktop) return const SizedBox.shrink();

    return Container(
      width: isCollapsed ? 48 : width,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: const Border(right: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(children: items),
    );
  }

  /// Handle desktop-specific keyboard navigation
  static bool handleDesktopKeyboard(KeyEvent event, BuildContext context) {
    if (!isDesktop) return false;

    // Handle Tab navigation
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        FocusScope.of(context).previousFocus();
      } else {
        FocusScope.of(context).nextFocus();
      }
      return true;
    }

    // Handle Escape key
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return true;
    }

    return false;
  }

  /// Get desktop-appropriate theme data
  static ThemeData getDesktopTheme({bool isDark = false}) {
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();

    return baseTheme.copyWith(
      // Desktop-specific theme customizations
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 48,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      buttonTheme: const ButtonThemeData(minWidth: 120, height: 36),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
