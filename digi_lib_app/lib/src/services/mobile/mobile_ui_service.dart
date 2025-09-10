import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for mobile-specific UI patterns and behaviors
class MobileUIService {
  /// Check if current platform is mobile
  static bool get isMobile {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }
  
  /// Check if current platform is Android
  static bool get isAndroid {
    return !kIsWeb && Platform.isAndroid;
  }
  
  /// Check if current platform is iOS
  static bool get isIOS {
    return !kIsWeb && Platform.isIOS;
  }
  
  /// Get platform-specific system UI overlay style
  static SystemUiOverlayStyle getSystemUIOverlayStyle({
    bool isDark = false,
  }) {
    if (!isMobile) return SystemUiOverlayStyle.dark;
    
    if (isAndroid) {
      return SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      );
    } else if (isIOS) {
      return SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      );
    }
    
    return SystemUiOverlayStyle.dark;
  }
  
  /// Get mobile-appropriate spacing and sizing
  static EdgeInsets getMobilePadding() {
    return const EdgeInsets.all(16.0);
  }
  
  /// Get mobile-appropriate button size
  static Size getMobileButtonSize() {
    return const Size(double.infinity, 48);
  }
  
  /// Get mobile-appropriate icon size
  static double getMobileIconSize() {
    return 24.0;
  }
  
  /// Get mobile-appropriate touch target size
  static double getTouchTargetSize() {
    return 48.0;
  }
  
  /// Create mobile-style bottom sheet
  static Future<T?> showMobileBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = false,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    if (!isMobile) {
      // Fallback to dialog for non-mobile platforms
      return showDialog<T>(
        context: context,
        builder: (context) => Dialog(child: child),
      );
    }
    
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => child,
    );
  }
  
  /// Create mobile-style app bar
  static PreferredSizeWidget createMobileAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool showBackButton = true,
    VoidCallback? onBackPressed,
  }) {
    return AppBar(
      title: Text(title),
      leading: leading,
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: getSystemUIOverlayStyle(),
      toolbarHeight: 56,
    );
  }
  
  /// Create mobile-style floating action button
  static Widget createMobileFAB({
    required VoidCallback onPressed,
    required Widget icon,
    String? tooltip,
    bool extended = false,
    String? label,
  }) {
    if (!isMobile) return const SizedBox.shrink();
    
    if (extended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
        tooltip: tooltip,
      );
    }
    
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      child: icon,
    );
  }
  
  /// Create mobile-style navigation bar
  static Widget createMobileBottomNavigation({
    required int currentIndex,
    required Function(int) onTap,
    required List<BottomNavigationBarItem> items,
  }) {
    if (!isMobile) return const SizedBox.shrink();
    
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: items,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
    );
  }
  
  /// Create mobile-style drawer
  static Widget createMobileDrawer({
    required List<Widget> items,
    Widget? header,
  }) {
    if (!isMobile) return const SizedBox.shrink();
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (header != null) header,
          ...items,
        ],
      ),
    );
  }
  
  /// Handle mobile-specific gestures
  static Widget createSwipeGestureHandler({
    required Widget child,
    VoidCallback? onSwipeLeft,
    VoidCallback? onSwipeRight,
    VoidCallback? onSwipeUp,
    VoidCallback? onSwipeDown,
  }) {
    if (!isMobile) return child;
    
    return GestureDetector(
      onPanEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond;
        const threshold = 500.0;
        
        if (velocity.dx.abs() > velocity.dy.abs()) {
          // Horizontal swipe
          if (velocity.dx > threshold) {
            onSwipeRight?.call();
          } else if (velocity.dx < -threshold) {
            onSwipeLeft?.call();
          }
        } else {
          // Vertical swipe
          if (velocity.dy > threshold) {
            onSwipeDown?.call();
          } else if (velocity.dy < -threshold) {
            onSwipeUp?.call();
          }
        }
      },
      child: child,
    );
  }
  
  /// Create mobile-style pull-to-refresh
  static Widget createPullToRefresh({
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    if (!isMobile) return child;
    
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }
  
  /// Handle mobile keyboard visibility
  static Widget handleKeyboardVisibility({
    required Widget child,
    bool resizeToAvoidBottomInset = true,
  }) {
    if (!isMobile) return child;
    
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: child,
    );
  }
  
  /// Get mobile-appropriate scroll physics
  static ScrollPhysics getMobileScrollPhysics() {
    if (isIOS) {
      return const BouncingScrollPhysics();
    } else if (isAndroid) {
      return const ClampingScrollPhysics();
    }
    return const ScrollPhysics();
  }
  
  /// Create mobile-style snackbar
  static void showMobileSnackBar({
    required BuildContext context,
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!isMobile) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// Handle mobile haptic feedback
  static void provideMobileHapticFeedback({
    HapticFeedbackType type = HapticFeedbackType.lightImpact,
  }) {
    if (!isMobile) return;
    
    switch (type) {
      case HapticFeedbackType.lightImpact:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.mediumImpact:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavyImpact:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selectionClick:
        HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.vibrate:
        HapticFeedback.vibrate();
        break;
    }
  }
  
  /// Get mobile-appropriate theme data
  static ThemeData getMobileTheme({bool isDark = false}) {
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
    
    return baseTheme.copyWith(
      // Mobile-specific theme customizations
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: getSystemUIOverlayStyle(isDark: isDark),
        toolbarHeight: 56,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 6,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        minWidth: double.infinity,
        height: 48,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// Get safe area padding for mobile devices
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    if (!isMobile) return EdgeInsets.zero;
    
    return MediaQuery.of(context).padding;
  }
  
  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  /// Check if device is a tablet (based on screen size)
  static bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600;
  }
}

/// Enum for haptic feedback types
enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
  vibrate,
}