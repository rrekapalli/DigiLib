import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ui/error_state.dart';
import '../models/api/api_error.dart';
import 'notification_service.dart';

/// Provider for the notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

/// Provider for the global error handler service
final errorHandlerServiceProvider = Provider<ErrorHandlerService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return ErrorHandlerService(notificationService);
});

/// Service for handling global errors and providing user feedback
class ErrorHandlerService {
  final NotificationService _notificationService;
  final StreamController<ErrorState> _errorStreamController = StreamController<ErrorState>.broadcast();
  final List<ErrorState> _errorHistory = [];
  static const int _maxErrorHistory = 100;

  ErrorHandlerService(this._notificationService) {
    // Set up global error handling
    FlutterError.onError = _handleFlutterError;
    PlatformDispatcher.instance.onError = _handlePlatformError;
  }

  /// Stream of error states for UI to listen to
  Stream<ErrorState> get errorStream => _errorStreamController.stream;

  /// Get error history
  List<ErrorState> get errorHistory => List.unmodifiable(_errorHistory);

  /// Handle any error and convert it to an ErrorState
  ErrorState handleError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    List<ErrorAction>? actions,
    bool showNotification = true,
  }) {
    final errorState = _convertToErrorState(error, stackTrace, context, actions);
    
    _addToHistory(errorState);
    _errorStreamController.add(errorState);
    
    if (showNotification) {
      _showErrorNotification(errorState);
    }
    
    // Log error for debugging
    _logError(errorState, stackTrace);
    
    return errorState;
  }

  /// Handle network errors with retry options
  ErrorState handleNetworkError(
    Object error, {
    String? context,
    VoidCallback? onRetry,
    bool showNotification = true,
  }) {
    final actions = <ErrorAction>[];
    
    if (onRetry != null) {
      actions.add(ErrorAction(
        label: 'Retry',
        onPressed: onRetry,
        isPrimary: true,
      ));
    }
    
    actions.add(ErrorAction(
      label: 'Go Offline',
      onPressed: () => _enableOfflineMode(),
    ));

    return handleError(
      error,
      context: context ?? 'Network operation',
      actions: actions,
      showNotification: showNotification,
    );
  }

  /// Handle file system errors
  ErrorState handleFileSystemError(
    Object error, {
    String? filePath,
    String? context,
    VoidCallback? onRetry,
    bool showNotification = true,
  }) {
    final actions = <ErrorAction>[];
    
    if (onRetry != null) {
      actions.add(ErrorAction(
        label: 'Retry',
        onPressed: onRetry,
        isPrimary: true,
      ));
    }

    return handleError(
      FileSystemException(
        _getFileSystemErrorMessage(error),
        path: filePath,
        originalError: error,
      ),
      context: context ?? 'File operation',
      actions: actions,
      showNotification: showNotification,
    );
  }

  /// Handle native worker errors with fallback options
  ErrorState handleNativeWorkerError(
    Object error, {
    String? operation,
    String? context,
    VoidCallback? onFallback,
    bool showNotification = true,
  }) {
    final actions = <ErrorAction>[];
    
    if (onFallback != null) {
      actions.add(ErrorAction(
        label: 'Use Server Rendering',
        onPressed: onFallback,
        isPrimary: true,
      ));
    }

    return handleError(
      NativeWorkerException(
        _getNativeWorkerErrorMessage(error),
        operation: operation,
        originalError: error,
      ),
      context: context ?? 'Document rendering',
      actions: actions,
      showNotification: showNotification,
    );
  }

  /// Handle sync conflicts
  ErrorState handleSyncConflict(
    Object error, {
    String? entityId,
    String? entityType,
    String? context,
    VoidCallback? onResolve,
    bool showNotification = true,
  }) {
    final actions = <ErrorAction>[];
    
    if (onResolve != null) {
      actions.add(ErrorAction(
        label: 'Resolve Conflict',
        onPressed: onResolve,
        isPrimary: true,
      ));
    }

    return handleError(
      SyncConflictException(
        _getSyncConflictErrorMessage(error),
        entityId: entityId,
        entityType: entityType,
        originalError: error,
      ),
      context: context ?? 'Data synchronization',
      actions: actions,
      showNotification: showNotification,
    );
  }

  /// Handle validation errors
  ErrorState handleValidationError(
    Object error, {
    Map<String, List<String>>? fieldErrors,
    String? context,
    bool showNotification = true,
  }) {
    return handleError(
      ValidationException(
        _getValidationErrorMessage(error),
        fieldErrors: fieldErrors,
        originalError: error,
      ),
      context: context ?? 'Input validation',
      showNotification: showNotification,
    );
  }

  /// Handle permission errors
  ErrorState handlePermissionError(
    Object error, {
    String? permission,
    String? context,
    VoidCallback? onRequestPermission,
    bool showNotification = true,
  }) {
    final actions = <ErrorAction>[];
    
    if (onRequestPermission != null) {
      actions.add(ErrorAction(
        label: 'Grant Permission',
        onPressed: onRequestPermission,
        isPrimary: true,
      ));
    }

    return handleError(
      PermissionException(
        _getPermissionErrorMessage(error),
        permission: permission,
        originalError: error,
      ),
      context: context ?? 'Permission check',
      actions: actions,
      showNotification: showNotification,
    );
  }

  /// Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
  }

  /// Dispose resources
  void dispose() {
    _errorStreamController.close();
  }

  // Private methods

  void _handleFlutterError(FlutterErrorDetails details) {
    handleError(
      details.exception,
      stackTrace: details.stack,
      context: details.context?.toString(),
      showNotification: false, // Don't show notifications for Flutter framework errors
    );
  }

  bool _handlePlatformError(Object error, StackTrace stackTrace) {
    handleError(
      error,
      stackTrace: stackTrace,
      context: 'Platform error',
      showNotification: false,
    );
    return true; // Indicate that the error was handled
  }

  ErrorState _convertToErrorState(
    Object error,
    StackTrace? stackTrace,
    String? context,
    List<ErrorAction>? actions,
  ) {
    if (error is ApiException) {
      return ErrorState.fromApiException(
        error,
        context: context,
        actions: actions ?? [],
      );
    }
    
    if (error is NetworkException) {
      return ErrorState.network(
        message: error.message,
        code: error.code,
        context: context,
        actions: actions ?? [],
      );
    }
    
    if (error is FileSystemException) {
      return ErrorState.fileSystem(
        message: error.message,
        code: error.path,
        context: context,
        actions: actions ?? [],
      );
    }
    
    if (error is NativeWorkerException) {
      return ErrorState.nativeWorker(
        message: error.message,
        code: error.operation,
        context: context,
        actions: actions ?? [],
      );
    }
    
    if (error is SyncConflictException) {
      return ErrorState.syncConflict(
        message: error.message,
        code: error.entityType,
        context: context,
        actions: actions ?? [],
      );
    }
    
    if (error is ValidationException) {
      return ErrorState.validation(
        message: error.message,
        context: context,
        actions: actions ?? [],
      );
    }
    
    if (error is PermissionException) {
      return ErrorState.permission(
        message: error.message,
        code: error.permission,
        context: context,
        actions: actions ?? [],
      );
    }

    // Handle platform-specific errors
    if (error is io.FileSystemException) {
      return ErrorState.fileSystem(
        message: 'File system error: ${error.message}',
        code: error.path,
        context: context,
        actions: actions ?? [],
      );
    }

    if (error is PlatformException) {
      return ErrorState(
        message: 'Platform error: ${error.message ?? 'Unknown platform error'}',
        type: ErrorType.unknown,
        severity: ErrorSeverity.error,
        code: error.code,
        details: error.details != null ? {'details': error.details} : null,
        timestamp: DateTime.now(),
        stackTrace: stackTrace,
        context: context,
        actions: actions ?? [],
      );
    }

    // Generic error handling
    return ErrorState(
      message: error.toString(),
      type: ErrorType.unknown,
      severity: ErrorSeverity.error,
      timestamp: DateTime.now(),
      stackTrace: stackTrace,
      context: context,
      actions: actions ?? [],
    );
  }

  void _addToHistory(ErrorState errorState) {
    _errorHistory.add(errorState);
    if (_errorHistory.length > _maxErrorHistory) {
      _errorHistory.removeAt(0);
    }
  }

  void _showErrorNotification(ErrorState errorState) {
    // Only show notifications for user-facing errors
    if (errorState.severity == ErrorSeverity.critical ||
        errorState.severity == ErrorSeverity.error) {
      _notificationService.showErrorNotification(
        _getNotificationTitle(errorState.type),
        errorState.message,
      );
    }
  }

  void _logError(ErrorState errorState, StackTrace? stackTrace) {
    if (kDebugMode) {
      debugPrint('Error [${errorState.type}]: ${errorState.message}');
      if (errorState.context != null) {
        debugPrint('Context: ${errorState.context}');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  String _getNotificationTitle(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'Connection Error';
      case ErrorType.authentication:
        return 'Authentication Error';
      case ErrorType.fileSystem:
        return 'File Error';
      case ErrorType.nativeWorker:
        return 'Rendering Error';
      case ErrorType.syncConflict:
        return 'Sync Conflict';
      case ErrorType.validation:
        return 'Validation Error';
      case ErrorType.permission:
        return 'Permission Error';
      case ErrorType.unknown:
        return 'Error';
    }
  }

  String _getFileSystemErrorMessage(Object error) {
    if (error is io.FileSystemException) {
      switch (error.osError?.errorCode) {
        case 2: // File not found
          return 'File not found. The file may have been moved or deleted.';
        case 5: // Access denied
          return 'Access denied. You don\'t have permission to access this file.';
        case 13: // Permission denied
          return 'Permission denied. Please check file permissions.';
        case 28: // No space left on device
          return 'Not enough storage space available.';
        default:
          return 'File system error: ${error.message}';
      }
    }
    return 'File operation failed: ${error.toString()}';
  }

  String _getNativeWorkerErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('memory')) {
      return 'Not enough memory to render document. Try closing other apps.';
    }
    if (message.contains('format') || message.contains('unsupported')) {
      return 'Unsupported document format. Server rendering will be used instead.';
    }
    if (message.contains('corrupt')) {
      return 'Document appears to be corrupted and cannot be rendered.';
    }
    return 'Document rendering failed. Falling back to server rendering.';
  }

  String _getSyncConflictErrorMessage(Object error) {
    return 'Data conflict detected. Your changes conflict with changes made on another device.';
  }

  String _getValidationErrorMessage(Object error) {
    return 'Please check your input and try again.';
  }

  String _getPermissionErrorMessage(Object error) {
    return 'Permission required to perform this action.';
  }

  void _enableOfflineMode() {
    // This would typically interact with a connectivity service
    // For now, just show a notification
    _notificationService.showInfoNotification(
      'Offline Mode',
      'App is now running in offline mode. Some features may be limited.',
    );
  }
}