import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Types of success notifications
enum SuccessType {
  info,
  success,
  warning,
  achievement,
}

/// Service for showing success notifications and confirmations
class SuccessNotificationService {
  static SuccessNotificationService? _instance;
  static SuccessNotificationService get instance => _instance ??= SuccessNotificationService._();
  
  SuccessNotificationService._();

  /// Show a success snackbar
  void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackBar(
      context,
      message: message,
      title: title,
      type: SuccessType.success,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show an info snackbar
  void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackBar(
      context,
      message: message,
      title: title,
      type: SuccessType.info,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show a warning snackbar
  void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackBar(
      context,
      message: message,
      title: title,
      type: SuccessType.warning,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show an achievement notification
  void showAchievement(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 5),
  }) {
    _showSnackBar(
      context,
      message: message,
      title: title ?? 'Achievement Unlocked!',
      type: SuccessType.achievement,
      duration: duration,
    );
  }

  /// Show a confirmation dialog
  Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  /// Show a success dialog
  Future<void> showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onPressed: onPressed,
      ),
    );
  }

  void _showSnackBar(
    BuildContext context, {
    required String message,
    String? title,
    required SuccessType type,
    required Duration duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color backgroundColor;
    Color foregroundColor;
    IconData icon;

    switch (type) {
      case SuccessType.success:
        backgroundColor = Colors.green;
        foregroundColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case SuccessType.info:
        backgroundColor = colorScheme.primary;
        foregroundColor = colorScheme.onPrimary;
        icon = Icons.info;
        break;
      case SuccessType.warning:
        backgroundColor = Colors.orange;
        foregroundColor = Colors.white;
        icon = Icons.warning;
        break;
      case SuccessType.achievement:
        backgroundColor = Colors.purple;
        foregroundColor = Colors.white;
        icon = Icons.emoji_events;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: foregroundColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: foregroundColor,
                onPressed: onAction,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
      ),
    );
  }
}

/// Confirmation dialog widget
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        isDestructive ? Icons.warning : Icons.help_outline,
        color: isDestructive ? Colors.red : Colors.blue,
        size: 32,
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// Success dialog widget
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 48,
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onPressed?.call();
          },
          child: Text(buttonText),
        ),
      ],
    );
  }
}

/// Toast notification widget for temporary messages
class ToastNotification extends StatefulWidget {
  final String message;
  final SuccessType type;
  final Duration duration;
  final VoidCallback? onDismiss;

  const ToastNotification({
    super.key,
    required this.message,
    this.type = SuccessType.info,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  @override
  State<ToastNotification> createState() => _ToastNotificationState();

  /// Show a toast notification
  static void show(
    BuildContext context, {
    required String message,
    SuccessType type = SuccessType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: ToastNotification(
          message: message,
          type: type,
          duration: duration,
          onDismiss: () {
            entry.remove();
            onDismiss?.call();
          },
        ),
      ),
    );

    overlay.insert(entry);
  }
}

class _ToastNotificationState extends State<ToastNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    IconData icon;

    switch (widget.type) {
      case SuccessType.success:
        backgroundColor = Colors.green;
        foregroundColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case SuccessType.info:
        backgroundColor = Theme.of(context).colorScheme.primary;
        foregroundColor = Theme.of(context).colorScheme.onPrimary;
        icon = Icons.info;
        break;
      case SuccessType.warning:
        backgroundColor = Colors.orange;
        foregroundColor = Colors.white;
        icon = Icons.warning;
        break;
      case SuccessType.achievement:
        backgroundColor = Colors.purple;
        foregroundColor = Colors.white;
        icon = Icons.emoji_events;
        break;
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            child: Row(
              children: [
                Icon(icon, color: foregroundColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foregroundColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _dismiss,
                  icon: Icon(Icons.close, color: foregroundColor, size: 20),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension to add success notification methods to BuildContext
extension SuccessNotificationContext on BuildContext {
  /// Show a success message
  void showSuccess(String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    SuccessNotificationService.instance.showSuccess(
      this,
      message: message,
      title: title,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show an info message
  void showInfo(String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    SuccessNotificationService.instance.showInfo(
      this,
      message: message,
      title: title,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show a warning message
  void showWarning(String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    SuccessNotificationService.instance.showWarning(
      this,
      message: message,
      title: title,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show an achievement notification
  void showAchievement(String message, {
    String? title,
    Duration duration = const Duration(seconds: 5),
  }) {
    SuccessNotificationService.instance.showAchievement(
      this,
      message: message,
      title: title,
      duration: duration,
    );
  }

  /// Show a confirmation dialog
  Future<bool> showConfirmation({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return SuccessNotificationService.instance.showConfirmation(
      this,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
    );
  }

  /// Show a success dialog
  Future<void> showSuccessDialog({
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return SuccessNotificationService.instance.showSuccessDialog(
      this,
      title: title,
      message: message,
      buttonText: buttonText,
      onPressed: onPressed,
    );
  }

  /// Show a toast notification
  void showToast(String message, {
    SuccessType type = SuccessType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) {
    ToastNotification.show(
      this,
      message: message,
      type: type,
      duration: duration,
      onDismiss: onDismiss,
    );
  }
}