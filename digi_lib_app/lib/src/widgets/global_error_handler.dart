import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ui/error_state.dart';
import '../services/error_handler_service.dart';
import 'error_dialog.dart';
import 'error_reporting_dialog.dart';

/// Widget that provides global error handling for the entire app
class GlobalErrorHandler extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalErrorHandler({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<GlobalErrorHandler> createState() => _GlobalErrorHandlerState();
}

class _GlobalErrorHandlerState extends ConsumerState<GlobalErrorHandler> {
  @override
  void initState() {
    super.initState();
    
    // Listen to error stream after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToErrors();
    });
  }

  void _listenToErrors() {
    final errorHandler = ref.read(errorHandlerServiceProvider);
    
    errorHandler.errorStream.listen((errorState) {
      if (mounted) {
        _handleError(errorState);
      }
    });
  }

  void _handleError(ErrorState errorState) {
    // Don't show dialogs for info level errors
    if (errorState.severity == ErrorSeverity.info) {
      return;
    }

    // Show appropriate dialog based on error type and severity
    if (errorState.type == ErrorType.network) {
      _showNetworkErrorDialog(errorState);
    } else if (errorState.severity == ErrorSeverity.critical) {
      _showCriticalErrorDialog(errorState);
    } else {
      _showStandardErrorDialog(errorState);
    }
  }

  void _showNetworkErrorDialog(ErrorState errorState) {
    // Find retry action if available
    final retryAction = errorState.actions
        .where((action) => action.label.toLowerCase().contains('retry'))
        .firstOrNull;
    
    // Find offline action if available
    final offlineAction = errorState.actions
        .where((action) => action.label.toLowerCase().contains('offline'))
        .firstOrNull;

    NetworkErrorDialog.show(
      context,
      message: errorState.message,
      onRetry: retryAction?.onPressed,
      onGoOffline: offlineAction?.onPressed,
    );
  }

  void _showCriticalErrorDialog(ErrorState errorState) {
    ErrorDialog.show(
      context,
      errorState.copyWith(
        actions: [
          ...errorState.actions,
          ErrorAction(
            label: 'Report Error',
            onPressed: () => _showErrorReporting(errorState),
          ),
        ],
      ),
    );
  }

  void _showStandardErrorDialog(ErrorState errorState) {
    // For validation errors, show a simpler dialog
    if (errorState.type == ErrorType.validation) {
      SimpleErrorDialog.show(
        context,
        title: 'Invalid Input',
        message: errorState.message,
        actions: errorState.actions,
      );
      return;
    }

    // For other errors, show full error dialog with reporting option
    ErrorDialog.show(
      context,
      errorState.copyWith(
        actions: [
          ...errorState.actions,
          if (errorState.severity == ErrorSeverity.error)
            ErrorAction(
              label: 'Report Error',
              onPressed: () => _showErrorReporting(errorState),
            ),
        ],
      ),
    );
  }

  void _showErrorReporting(ErrorState errorState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Error'),
        content: Text('Error: ${errorState.message}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              debugPrint('Error report submitted for: ${errorState.message}');
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension to add error handling methods to BuildContext
extension ErrorHandlingContext on BuildContext {
  /// Show an error using the global error handler
  void showError(Object error, {
    StackTrace? stackTrace,
    String? context,
    List<ErrorAction>? actions,
  }) {
    final container = ProviderScope.containerOf(this);
    final errorHandler = container.read(errorHandlerServiceProvider);
    
    errorHandler.handleError(
      error,
      stackTrace: stackTrace,
      context: context,
      actions: actions,
    );
  }

  /// Show a network error with retry options
  void showNetworkError(Object error, {
    String? context,
    VoidCallback? onRetry,
  }) {
    final container = ProviderScope.containerOf(this);
    final errorHandler = container.read(errorHandlerServiceProvider);
    
    errorHandler.handleNetworkError(
      error,
      context: context,
      onRetry: onRetry,
    );
  }

  /// Show a simple error message
  void showSimpleError(String message, {String? title}) {
    SimpleErrorDialog.show(
      this,
      title: title ?? 'Error',
      message: message,
    );
  }

  /// Show a validation error
  void showValidationError(String message, {
    Map<String, List<String>>? fieldErrors,
  }) {
    final container = ProviderScope.containerOf(this);
    final errorHandler = container.read(errorHandlerServiceProvider);
    
    errorHandler.handleValidationError(
      ValidationException(message, fieldErrors: fieldErrors),
    );
  }

  /// Show feedback dialog
  void showFeedbackDialog({
    Function(String feedback, int rating)? onSubmit,
  }) {
    showDialog<void>(
      context: this,
      builder: (context) => FeedbackDialog(onSubmit: onSubmit),
    );
  }
}

/// Mixin for widgets that need error handling capabilities
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  /// Handle an error with the global error handler
  void handleError(Object error, {
    StackTrace? stackTrace,
    String? context,
    List<ErrorAction>? actions,
  }) {
    if (mounted) {
      this.context.showError(
        error,
        stackTrace: stackTrace,
        context: context,
        actions: actions,
      );
    }
  }

  /// Handle a network error with retry options
  void handleNetworkError(Object error, {
    String? context,
    VoidCallback? onRetry,
  }) {
    if (mounted) {
      this.context.showNetworkError(
        error,
        context: context,
        onRetry: onRetry,
      );
    }
  }

  /// Show a simple error message
  void showSimpleError(String message, {String? title}) {
    if (mounted) {
      context.showSimpleError(message, title: title);
    }
  }

  /// Show a validation error
  void showValidationError(String message, {
    Map<String, List<String>>? fieldErrors,
  }) {
    if (mounted) {
      context.showValidationError(message, fieldErrors: fieldErrors);
    }
  }
}