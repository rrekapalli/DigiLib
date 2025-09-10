import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ui/error_state.dart';
import '../utils/constants.dart';

/// A dialog that displays error information with contextual actions
class ErrorDialog extends StatelessWidget {
  final ErrorState errorState;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    required this.errorState,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: _buildErrorIcon(),
      title: Text(_getTitle()),
      content: _buildContent(context),
      actions: _buildActions(context),
    );
  }

  Widget _buildErrorIcon() {
    IconData iconData;
    Color color;

    switch (errorState.severity) {
      case ErrorSeverity.info:
        iconData = Icons.info_outline;
        color = Colors.blue;
        break;
      case ErrorSeverity.warning:
        iconData = Icons.warning_amber_outlined;
        color = Colors.orange;
        break;
      case ErrorSeverity.error:
        iconData = Icons.error_outline;
        color = Colors.red;
        break;
      case ErrorSeverity.critical:
        iconData = Icons.dangerous_outlined;
        color = Colors.red.shade700;
        break;
    }

    return Icon(iconData, color: color, size: 32);
  }

  String _getTitle() {
    switch (errorState.type) {
      case ErrorType.network:
        return 'Connection Problem';
      case ErrorType.authentication:
        return 'Authentication Required';
      case ErrorType.fileSystem:
        return 'File Access Error';
      case ErrorType.nativeWorker:
        return 'Rendering Error';
      case ErrorType.syncConflict:
        return 'Sync Conflict';
      case ErrorType.validation:
        return 'Invalid Input';
      case ErrorType.permission:
        return 'Permission Required';
      case ErrorType.unknown:
        return 'Error';
    }
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          errorState.message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (errorState.context != null) ...[
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            'Context: ${errorState.context}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (errorState.code != null) ...[
          const SizedBox(height: AppConstants.defaultPadding / 2),
          Text(
            'Error Code: ${errorState.code}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
        if (errorState.details != null && errorState.details!.isNotEmpty) ...[
          const SizedBox(height: AppConstants.defaultPadding),
          ExpansionTile(
            title: Text(
              'Technical Details',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
                child: Text(
                  _formatDetails(errorState.details!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    // Add custom actions from error state
    for (final action in errorState.actions) {
      if (action.isPrimary) {
        actions.add(
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              action.onPressed();
            },
            child: Text(action.label),
          ),
        );
      } else {
        actions.add(
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              action.onPressed();
            },
            child: Text(action.label),
          ),
        );
      }
    }

    // Add copy error details action if there are technical details
    if (errorState.details != null || errorState.code != null) {
      actions.add(
        TextButton.icon(
          onPressed: () => _copyErrorDetails(context),
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy Details'),
        ),
      );
    }

    // Add dismiss action
    actions.add(
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          onDismiss?.call();
        },
        child: const Text('Dismiss'),
      ),
    );

    return actions;
  }

  String _formatDetails(Map<String, dynamic> details) {
    final buffer = StringBuffer();
    for (final entry in details.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    return buffer.toString().trim();
  }

  void _copyErrorDetails(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('Error: ${errorState.message}');
    if (errorState.code != null) {
      buffer.writeln('Code: ${errorState.code}');
    }
    if (errorState.context != null) {
      buffer.writeln('Context: ${errorState.context}');
    }
    buffer.writeln('Type: ${errorState.type}');
    buffer.writeln('Severity: ${errorState.severity}');
    buffer.writeln('Timestamp: ${errorState.timestamp}');
    if (errorState.details != null) {
      buffer.writeln('Details:');
      buffer.writeln(_formatDetails(errorState.details!));
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error details copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Show an error dialog
  static Future<void> show(
    BuildContext context,
    ErrorState errorState, {
    VoidCallback? onDismiss,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        errorState: errorState,
        onDismiss: onDismiss,
      ),
    );
  }
}

/// A simplified error dialog for quick error display
class SimpleErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<ErrorAction> actions;

  const SimpleErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.error_outline, color: Colors.red, size: 32),
      title: Text(title),
      content: Text(message),
      actions: [
        ...actions.map((action) => action.isPrimary
            ? FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  action.onPressed();
                },
                child: Text(action.label),
              )
            : TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  action.onPressed();
                },
                child: Text(action.label),
              )),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  /// Show a simple error dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    List<ErrorAction> actions = const [],
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => SimpleErrorDialog(
        title: title,
        message: message,
        actions: actions,
      ),
    );
  }
}

/// A network error dialog with retry and offline options
class NetworkErrorDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onGoOffline;

  const NetworkErrorDialog({
    super.key,
    required this.message,
    this.onRetry,
    this.onGoOffline,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.wifi_off, color: Colors.orange, size: 32),
      title: const Text('Connection Problem'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: AppConstants.defaultPadding),
          const Text(
            'Check your internet connection and try again, or continue in offline mode.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: [
        if (onRetry != null)
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        if (onGoOffline != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onGoOffline!();
            },
            child: const Text('Go Offline'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }

  /// Show a network error dialog
  static Future<void> show(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onGoOffline,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => NetworkErrorDialog(
        message: message,
        onRetry: onRetry,
        onGoOffline: onGoOffline,
      ),
    );
  }
}