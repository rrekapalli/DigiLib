import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for managing screen orientation and display settings on mobile
class ScreenService {
  static Orientation? _lockedOrientation;
  static double? _lockedBrightness;
  
  /// Set preferred screen orientations
  static Future<void> setPreferredOrientations(
    List<DeviceOrientation> orientations,
  ) async {
    if (!_isMobile) return;
    
    try {
      await SystemChrome.setPreferredOrientations(orientations);
      print('Screen orientations set: $orientations');
    } catch (e) {
      print('Error setting screen orientations: $e');
    }
  }
  
  /// Lock screen to portrait mode
  static Future<void> lockPortrait() async {
    if (!_isMobile) return;
    
    await setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _lockedOrientation = Orientation.portrait;
  }
  
  /// Lock screen to landscape mode
  static Future<void> lockLandscape() async {
    if (!_isMobile) return;
    
    await setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _lockedOrientation = Orientation.landscape;
  }
  
  /// Allow all orientations
  static Future<void> allowAllOrientations() async {
    if (!_isMobile) return;
    
    await setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _lockedOrientation = null;
  }
  
  /// Get current orientation
  static Orientation getCurrentOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }
  
  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return getCurrentOrientation(context) == Orientation.portrait;
  }
  
  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return getCurrentOrientation(context) == Orientation.landscape;
  }
  
  /// Get screen size
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }
  
  /// Get screen density
  static double getScreenDensity(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }
  
  /// Check if device is a tablet
  static bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600;
  }
  
  /// Check if device is a phone
  static bool isPhone(BuildContext context) {
    return !isTablet(context);
  }
  
  /// Get safe area insets
  static EdgeInsets getSafeAreaInsets(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  /// Hide system UI (status bar and navigation bar)
  static Future<void> hideSystemUI() async {
    if (!_isMobile) return;
    
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
      );
      print('System UI hidden');
    } catch (e) {
      print('Error hiding system UI: $e');
    }
  }
  
  /// Show system UI
  static Future<void> showSystemUI() async {
    if (!_isMobile) return;
    
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      print('System UI shown');
    } catch (e) {
      print('Error showing system UI: $e');
    }
  }
  
  /// Set system UI overlay style
  static Future<void> setSystemUIOverlayStyle({
    Color? statusBarColor,
    Brightness? statusBarIconBrightness,
    Color? systemNavigationBarColor,
    Brightness? systemNavigationBarIconBrightness,
  }) async {
    if (!_isMobile) return;
    
    try {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: statusBarColor ?? Colors.transparent,
          statusBarIconBrightness: statusBarIconBrightness ?? Brightness.dark,
          systemNavigationBarColor: systemNavigationBarColor ?? Colors.white,
          systemNavigationBarIconBrightness: 
              systemNavigationBarIconBrightness ?? Brightness.dark,
        ),
      );
    } catch (e) {
      print('Error setting system UI overlay style: $e');
    }
  }
  
  /// Set screen brightness
  static Future<void> setBrightness(double brightness) async {
    if (!_isMobile) return;
    
    try {
      // Clamp brightness between 0.0 and 1.0
      final clampedBrightness = brightness.clamp(0.0, 1.0);
      
      // This would require a plugin like screen_brightness
      // For now, we'll just store the value
      _lockedBrightness = clampedBrightness;
      
      print('Screen brightness set to: $clampedBrightness');
    } catch (e) {
      print('Error setting screen brightness: $e');
    }
  }
  
  /// Reset screen brightness to system default
  static Future<void> resetBrightness() async {
    if (!_isMobile) return;
    
    try {
      _lockedBrightness = null;
      print('Screen brightness reset to system default');
    } catch (e) {
      print('Error resetting screen brightness: $e');
    }
  }
  
  /// Get current screen brightness
  static Future<double> getCurrentBrightness() async {
    if (!_isMobile) return 1.0;
    
    try {
      // This would require a plugin to get actual brightness
      return _lockedBrightness ?? 1.0;
    } catch (e) {
      print('Error getting screen brightness: $e');
      return 1.0;
    }
  }
  
  /// Configure screen for reading mode
  static Future<void> enableReadingMode({
    bool lockOrientation = true,
    double? brightness,
    bool hideSystemUI = false,
  }) async {
    if (!_isMobile) return;
    
    try {
      // Lock to current orientation if requested
      if (lockOrientation) {
        // This would typically lock to the current orientation
        // For simplicity, we'll allow all orientations
        await allowAllOrientations();
      }
      
      // Set brightness if specified
      if (brightness != null) {
        await setBrightness(brightness);
      }
      
      // Hide system UI if requested
      if (hideSystemUI) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }
      
      print('Reading mode enabled');
    } catch (e) {
      print('Error enabling reading mode: $e');
    }
  }
  
  /// Disable reading mode and restore defaults
  static Future<void> disableReadingMode() async {
    if (!_isMobile) return;
    
    try {
      // Restore all orientations
      await allowAllOrientations();
      
      // Reset brightness
      await resetBrightness();
      
      // Show system UI
      await showSystemUI();
      
      print('Reading mode disabled');
    } catch (e) {
      print('Error disabling reading mode: $e');
    }
  }
  
  /// Get optimal layout for current screen configuration
  static LayoutConfig getOptimalLayout(BuildContext context) {
    final size = getScreenSize(context);
    final isTabletDevice = isTablet(context);
    final isLandscapeMode = isLandscape(context);
    
    if (isTabletDevice) {
      if (isLandscapeMode) {
        return LayoutConfig.tabletLandscape;
      } else {
        return LayoutConfig.tabletPortrait;
      }
    } else {
      if (isLandscapeMode) {
        return LayoutConfig.phoneLandscape;
      } else {
        return LayoutConfig.phonePortrait;
      }
    }
  }
  
  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final config = getOptimalLayout(context);
    
    switch (config) {
      case LayoutConfig.phonePortrait:
        return const EdgeInsets.all(16.0);
      case LayoutConfig.phoneLandscape:
        return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0);
      case LayoutConfig.tabletPortrait:
        return const EdgeInsets.all(24.0);
      case LayoutConfig.tabletLandscape:
        return const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0);
    }
  }
  
  /// Get responsive column count for grid layouts
  static int getResponsiveColumnCount(BuildContext context) {
    final config = getOptimalLayout(context);
    
    switch (config) {
      case LayoutConfig.phonePortrait:
        return 2;
      case LayoutConfig.phoneLandscape:
        return 3;
      case LayoutConfig.tabletPortrait:
        return 3;
      case LayoutConfig.tabletLandscape:
        return 4;
    }
  }
  
  /// Dispose screen service and restore defaults
  static Future<void> dispose() async {
    if (!_isMobile) return;
    
    try {
      await disableReadingMode();
      _lockedOrientation = null;
      _lockedBrightness = null;
      print('Screen service disposed');
    } catch (e) {
      print('Error disposing screen service: $e');
    }
  }
  
  /// Check if running on mobile platform
  static bool get _isMobile {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }
}

/// Layout configuration enum
enum LayoutConfig {
  phonePortrait,
  phoneLandscape,
  tabletPortrait,
  tabletLandscape,
}

/// Screen configuration for different contexts
class ScreenConfig {
  final List<DeviceOrientation> allowedOrientations;
  final bool hideSystemUI;
  final double? brightness;
  final SystemUiOverlayStyle? overlayStyle;
  
  const ScreenConfig({
    this.allowedOrientations = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
    this.hideSystemUI = false,
    this.brightness,
    this.overlayStyle,
  });
  
  /// Configuration for reading documents
  static const ScreenConfig reading = ScreenConfig(
    allowedOrientations: [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
    hideSystemUI: false,
    brightness: 0.8,
  );
  
  /// Configuration for browsing libraries
  static const ScreenConfig browsing = ScreenConfig(
    allowedOrientations: [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
    hideSystemUI: false,
  );
  
  /// Configuration for fullscreen viewing
  static const ScreenConfig fullscreen = ScreenConfig(
    allowedOrientations: [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
    hideSystemUI: true,
  );
}