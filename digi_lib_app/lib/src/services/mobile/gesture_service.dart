import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for handling mobile-specific gestures and interactions
class GestureService {
  static const double _swipeThreshold = 100.0;
  static const double _velocityThreshold = 500.0;

  /// Create a swipe gesture detector
  static Widget createSwipeDetector({
    required Widget child,
    VoidCallback? onSwipeLeft,
    VoidCallback? onSwipeRight,
    VoidCallback? onSwipeUp,
    VoidCallback? onSwipeDown,
    double threshold = _swipeThreshold,
    double velocityThreshold = _velocityThreshold,
  }) {
    if (!_isMobile) return child;

    return GestureDetector(
      onPanEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond;

        // Check if velocity is above threshold
        if (velocity.distance < velocityThreshold) return;

        // Determine swipe direction
        if (velocity.dx.abs() > velocity.dy.abs()) {
          // Horizontal swipe
          if (velocity.dx > 0) {
            onSwipeRight?.call();
            _provideHapticFeedback();
          } else {
            onSwipeLeft?.call();
            _provideHapticFeedback();
          }
        } else {
          // Vertical swipe
          if (velocity.dy > 0) {
            onSwipeDown?.call();
            _provideHapticFeedback();
          } else {
            onSwipeUp?.call();
            _provideHapticFeedback();
          }
        }
      },
      child: child,
    );
  }

  /// Create a pinch-to-zoom gesture detector
  static Widget createPinchZoomDetector({
    required Widget child,
    Function(double scale)? onScaleUpdate,
    VoidCallback? onScaleStart,
    VoidCallback? onScaleEnd,
    double minScale = 0.5,
    double maxScale = 3.0,
  }) {
    if (!_isMobile) return child;

    return GestureDetector(
      onScaleStart: (details) {
        onScaleStart?.call();
      },
      onScaleUpdate: (details) {
        final scale = details.scale.clamp(minScale, maxScale);
        onScaleUpdate?.call(scale);
      },
      onScaleEnd: (details) {
        onScaleEnd?.call();
        _provideHapticFeedback();
      },
      child: child,
    );
  }

  /// Create a long press gesture detector
  static Widget createLongPressDetector({
    required Widget child,
    VoidCallback? onLongPress,
    VoidCallback? onLongPressStart,
    VoidCallback? onLongPressEnd,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    if (!_isMobile) return child;

    return GestureDetector(
      onLongPressStart: (details) {
        onLongPressStart?.call();
        _provideHapticFeedback(HapticFeedbackType.mediumImpact);
      },
      onLongPress: () {
        onLongPress?.call();
        _provideHapticFeedback(HapticFeedbackType.heavyImpact);
      },
      onLongPressEnd: (details) {
        onLongPressEnd?.call();
      },
      child: child,
    );
  }

  /// Create a double tap gesture detector
  static Widget createDoubleTapDetector({
    required Widget child,
    VoidCallback? onDoubleTap,
    VoidCallback? onSingleTap,
  }) {
    if (!_isMobile) return child;

    return GestureDetector(
      onTap: onSingleTap,
      onDoubleTap: () {
        onDoubleTap?.call();
        _provideHapticFeedback();
      },
      child: child,
    );
  }

  /// Create a pan gesture detector for dragging
  static Widget createPanDetector({
    required Widget child,
    Function(DragUpdateDetails)? onPanUpdate,
    Function(DragStartDetails)? onPanStart,
    Function(DragEndDetails)? onPanEnd,
  }) {
    if (!_isMobile) return child;

    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: child,
    );
  }

  /// Create a rotation gesture detector
  static Widget createRotationDetector({
    required Widget child,
    Function(double angle)? onRotationUpdate,
    VoidCallback? onRotationStart,
    VoidCallback? onRotationEnd,
  }) {
    if (!_isMobile) return child;

    double baseAngle = 0.0;

    return GestureDetector(
      onScaleStart: (details) {
        baseAngle = 0.0;
        onRotationStart?.call();
      },
      onScaleUpdate: (details) {
        final angle = details.rotation - baseAngle;
        onRotationUpdate?.call(angle);
      },
      onScaleEnd: (details) {
        onRotationEnd?.call();
        _provideHapticFeedback();
      },
      child: child,
    );
  }

  /// Create a multi-gesture detector combining multiple gestures
  static Widget createMultiGestureDetector({
    required Widget child,

    // Tap gestures
    VoidCallback? onTap,
    VoidCallback? onDoubleTap,
    VoidCallback? onLongPress,

    // Swipe gestures
    VoidCallback? onSwipeLeft,
    VoidCallback? onSwipeRight,
    VoidCallback? onSwipeUp,
    VoidCallback? onSwipeDown,

    // Scale gestures
    Function(double scale)? onScaleUpdate,
    VoidCallback? onScaleStart,
    VoidCallback? onScaleEnd,

    // Pan gestures
    Function(DragUpdateDetails)? onPanUpdate,
    Function(DragStartDetails)? onPanStart,
    Function(DragEndDetails)? onPanEnd,
  }) {
    if (!_isMobile) return child;

    Widget detector = child;

    // Add swipe detection
    if (onSwipeLeft != null ||
        onSwipeRight != null ||
        onSwipeUp != null ||
        onSwipeDown != null) {
      detector = createSwipeDetector(
        onSwipeLeft: onSwipeLeft,
        onSwipeRight: onSwipeRight,
        onSwipeUp: onSwipeUp,
        onSwipeDown: onSwipeDown,
        child: detector,
      );
    }

    // Add scale detection
    if (onScaleUpdate != null || onScaleStart != null || onScaleEnd != null) {
      detector = createPinchZoomDetector(
        onScaleUpdate: onScaleUpdate,
        onScaleStart: onScaleStart,
        onScaleEnd: onScaleEnd,
        child: detector,
      );
    }

    // Add tap detection
    if (onTap != null || onDoubleTap != null) {
      detector = createDoubleTapDetector(
        onSingleTap: onTap,
        onDoubleTap: onDoubleTap,
        child: detector,
      );
    }

    // Add long press detection
    if (onLongPress != null) {
      detector = createLongPressDetector(
        onLongPress: onLongPress,
        child: detector,
      );
    }

    // Add pan detection
    if (onPanUpdate != null || onPanStart != null || onPanEnd != null) {
      detector = createPanDetector(
        onPanUpdate: onPanUpdate,
        onPanStart: onPanStart,
        onPanEnd: onPanEnd,
        child: detector,
      );
    }

    return detector;
  }

  /// Create a page view gesture handler for document reading
  static Widget createPageViewGestureHandler({
    required Widget child,
    VoidCallback? onNextPage,
    VoidCallback? onPreviousPage,
    Function(double scale)? onZoom,
    VoidCallback? onDoubleTapZoom,
    Function(Offset position)? onTapPosition,
  }) {
    if (!_isMobile) return child;

    return createMultiGestureDetector(
      onSwipeLeft: onNextPage,
      onSwipeRight: onPreviousPage,
      onDoubleTap: onDoubleTapZoom,
      onScaleUpdate: onZoom,
      onTap: () {
        // Handle tap for page navigation zones
        // Implementation would determine tap position and call onTapPosition
      },
      child: child,
    );
  }

  /// Create a list item gesture handler for swipe actions
  static Widget createListItemGestureHandler({
    required Widget child,
    VoidCallback? onSwipeToDelete,
    VoidCallback? onSwipeToArchive,
    VoidCallback? onSwipeToShare,
    VoidCallback? onLongPressMenu,
  }) {
    if (!_isMobile) return child;

    return createMultiGestureDetector(
      onSwipeLeft: onSwipeToDelete,
      onSwipeRight: onSwipeToArchive,
      onSwipeUp: onSwipeToShare,
      onLongPress: onLongPressMenu,
      child: child,
    );
  }

  /// Provide haptic feedback
  static void _provideHapticFeedback([
    HapticFeedbackType type = HapticFeedbackType.lightImpact,
  ]) {
    if (!_isMobile) return;

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

  /// Get gesture sensitivity based on device type
  static double getGestureSensitivity(BuildContext context) {
    if (!_isMobile) return 1.0;

    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;

    // Tablets need less sensitive gestures due to larger screens
    return isTablet ? 0.8 : 1.0;
  }

  /// Check if device supports advanced gestures
  static bool supportsAdvancedGestures() {
    return _isMobile;
  }

  /// Check if running on mobile platform
  static bool get _isMobile {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
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

/// Gesture configuration for different contexts
class GestureConfig {
  final double swipeThreshold;
  final double velocityThreshold;
  final double pinchThreshold;
  final bool enableHapticFeedback;
  final Duration longPressDuration;

  const GestureConfig({
    this.swipeThreshold = 100.0,
    this.velocityThreshold = 500.0,
    this.pinchThreshold = 0.1,
    this.enableHapticFeedback = true,
    this.longPressDuration = const Duration(milliseconds: 500),
  });

  /// Configuration for reading documents
  static const GestureConfig reading = GestureConfig(
    swipeThreshold: 50.0,
    velocityThreshold: 300.0,
    enableHapticFeedback: false, // Avoid interrupting reading
  );

  /// Configuration for browsing lists
  static const GestureConfig browsing = GestureConfig(
    swipeThreshold: 80.0,
    velocityThreshold: 400.0,
    enableHapticFeedback: true,
  );

  /// Configuration for image viewing
  static const GestureConfig imageViewing = GestureConfig(
    swipeThreshold: 100.0,
    velocityThreshold: 500.0,
    pinchThreshold: 0.05, // More sensitive for zooming
    enableHapticFeedback: false,
  );
}
