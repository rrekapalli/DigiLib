import 'dart:io';
import 'ffi_native_rendering_worker.dart';

/// Comprehensive error handler for native rendering operations
class NativeRenderingErrorHandler {
  /// Handle and categorize native rendering errors
  static NativeRenderingError handleError(Object error, StackTrace stackTrace) {
    if (error is NativeRenderingException) {
      return _categorizeNativeRenderingException(error);
    }
    
    if (error is FileSystemException) {
      return _handleFileSystemError(error);
    }
    
    if (error is ArgumentError) {
      return _handleArgumentError(error);
    }
    
    if (error is UnsupportedError) {
      return _handleUnsupportedError(error);
    }
    
    // Generic error
    return NativeRenderingError(
      type: NativeRenderingErrorType.unknown,
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
      isRecoverable: false,
    );
  }

  static NativeRenderingError _categorizeNativeRenderingException(NativeRenderingException exception) {
    final message = exception.message.toLowerCase();
    
    // File-related errors
    if (message.contains('file not found') || message.contains('no such file')) {
      return NativeRenderingError(
        type: NativeRenderingErrorType.fileNotFound,
        message: exception.message,
        details: exception.details,
        originalError: exception,
        isRecoverable: false,
        suggestedAction: 'Verify that the file exists and is accessible',
      );
    }
    
    // Permission errors
    if (message.contains('permission denied') || message.contains('access denied')) {
      return NativeRenderingError(
        type: NativeRenderingErrorType.permissionDenied,
        message: exception.message,
        details: exception.details,
        originalError: exception,
        isRecoverable: false,
        suggestedAction: 'Check file permissions and ensure the application has read access',
      );
    }
    
    // Corrupted file errors
    if (message.contains('corrupted') || message.contains('invalid format') || message.contains('malformed')) {
      return NativeRenderingError(
        type: NativeRenderingErrorType.corruptedFile,
        message: exception.message,
        details: exception.details,
        originalError: exception,
        isRecoverable: false,
        suggestedAction: 'The file may be corrupted or in an unsupported format',
      );
    }
    
    // Memory errors
    if (message.contains('out of memory') || message.contains('memory allocation')) {
      return NativeRenderingError(
        type: NativeRenderingErrorType.memoryError,
        message: exception.message,
        details: exception.details,
        originalError: exception,
        isRecoverable: true,
        suggestedAction: 'Try reducing the DPI or closing other applications to free memory',
      );
    }
    
    // Library not available
    if (message.contains('library not initialized') || message.contains('not available')) {
      return NativeRenderingError(
        type: NativeRenderingErrorType.libraryNotAvailable,
        message: exception.message,
        details: exception.details,
        originalError: exception,
        isRecoverable: true,
        suggestedAction: 'Native rendering library is not available, falling back to server rendering',
      );
    }
    
    // Rendering errors
    if (message.contains('rendering failed') || message.contains('render error')) {
      return NativeRenderingError(
        type: NativeRenderingErrorType.renderingFailed,
        message: exception.message,
        details: exception.details,
        originalError: exception,
        isRecoverable: true,
        suggestedAction: 'Try rendering with different parameters or use server rendering',
      );
    }
    
    // Generic native rendering error
    return NativeRenderingError(
      type: NativeRenderingErrorType.nativeRenderingError,
      message: exception.message,
      details: exception.details,
      originalError: exception,
      isRecoverable: true,
    );
  }

  static NativeRenderingError _handleFileSystemError(FileSystemException error) {
    switch (error.osError?.errorCode) {
      case 2: // File not found (Unix/Windows)
      case 3: // Path not found (Windows)
        return NativeRenderingError(
          type: NativeRenderingErrorType.fileNotFound,
          message: 'File not found: ${error.path}',
          originalError: error,
          isRecoverable: false,
          suggestedAction: 'Verify that the file exists at the specified path',
        );
      
      case 5: // Access denied (Windows)
      case 13: // Permission denied (Unix)
        return NativeRenderingError(
          type: NativeRenderingErrorType.permissionDenied,
          message: 'Permission denied: ${error.path}',
          originalError: error,
          isRecoverable: false,
          suggestedAction: 'Check file permissions and ensure the application has read access',
        );
      
      case 28: // No space left on device (Unix)
      case 112: // Disk full (Windows)
        return NativeRenderingError(
          type: NativeRenderingErrorType.diskFull,
          message: 'Insufficient disk space',
          originalError: error,
          isRecoverable: true,
          suggestedAction: 'Free up disk space and try again',
        );
      
      default:
        return NativeRenderingError(
          type: NativeRenderingErrorType.fileSystemError,
          message: error.message,
          originalError: error,
          isRecoverable: false,
        );
    }
  }

  static NativeRenderingError _handleArgumentError(ArgumentError error) {
    return NativeRenderingError(
      type: NativeRenderingErrorType.invalidArgument,
      message: 'Invalid argument: ${error.message}',
      originalError: error,
      isRecoverable: true,
      suggestedAction: 'Check the input parameters and ensure they are valid',
    );
  }

  static NativeRenderingError _handleUnsupportedError(UnsupportedError error) {
    return NativeRenderingError(
      type: NativeRenderingErrorType.unsupportedOperation,
      message: 'Unsupported operation: ${error.message}',
      originalError: error,
      isRecoverable: false,
      suggestedAction: 'This operation is not supported on the current platform',
    );
  }

  /// Get recovery suggestions based on error type
  static List<String> getRecoverySuggestions(NativeRenderingErrorType errorType) {
    switch (errorType) {
      case NativeRenderingErrorType.fileNotFound:
        return [
          'Verify the file path is correct',
          'Check if the file has been moved or deleted',
          'Ensure the file is accessible from the application',
        ];
      
      case NativeRenderingErrorType.permissionDenied:
        return [
          'Check file permissions',
          'Run the application with appropriate privileges',
          'Ensure the file is not locked by another application',
        ];
      
      case NativeRenderingErrorType.corruptedFile:
        return [
          'Try opening the file with another application to verify it\'s not corrupted',
          'Re-download or restore the file from a backup',
          'Convert the file to a different format',
        ];
      
      case NativeRenderingErrorType.memoryError:
        return [
          'Reduce the rendering DPI to use less memory',
          'Close other applications to free up memory',
          'Try rendering smaller sections of the document',
        ];
      
      case NativeRenderingErrorType.libraryNotAvailable:
        return [
          'Install the required native rendering library',
          'Use server-side rendering as an alternative',
          'Check if the platform is supported',
        ];
      
      case NativeRenderingErrorType.renderingFailed:
        return [
          'Try rendering with different parameters',
          'Use server-side rendering as fallback',
          'Check if the document format is supported',
        ];
      
      case NativeRenderingErrorType.diskFull:
        return [
          'Free up disk space',
          'Clear application cache',
          'Move files to external storage',
        ];
      
      default:
        return [
          'Try the operation again',
          'Restart the application',
          'Contact support if the problem persists',
        ];
    }
  }

  /// Check if an error is likely to be resolved by retrying
  static bool shouldRetry(NativeRenderingError error) {
    switch (error.type) {
      case NativeRenderingErrorType.memoryError:
      case NativeRenderingErrorType.renderingFailed:
      case NativeRenderingErrorType.networkError:
        return true;
      
      case NativeRenderingErrorType.fileNotFound:
      case NativeRenderingErrorType.permissionDenied:
      case NativeRenderingErrorType.corruptedFile:
      case NativeRenderingErrorType.unsupportedOperation:
        return false;
      
      default:
        return error.isRecoverable;
    }
  }
}

/// Detailed error information for native rendering operations
class NativeRenderingError {
  final NativeRenderingErrorType type;
  final String message;
  final String? details;
  final Object? originalError;
  final StackTrace? stackTrace;
  final bool isRecoverable;
  final String? suggestedAction;

  const NativeRenderingError({
    required this.type,
    required this.message,
    this.details,
    this.originalError,
    this.stackTrace,
    required this.isRecoverable,
    this.suggestedAction,
  });

  /// Get user-friendly error message
  String get userFriendlyMessage {
    switch (type) {
      case NativeRenderingErrorType.fileNotFound:
        return 'The document file could not be found.';
      case NativeRenderingErrorType.permissionDenied:
        return 'Permission denied while accessing the document.';
      case NativeRenderingErrorType.corruptedFile:
        return 'The document file appears to be corrupted or in an unsupported format.';
      case NativeRenderingErrorType.memoryError:
        return 'Not enough memory available to render the document.';
      case NativeRenderingErrorType.libraryNotAvailable:
        return 'Native rendering is not available on this device.';
      case NativeRenderingErrorType.renderingFailed:
        return 'Failed to render the document page.';
      case NativeRenderingErrorType.diskFull:
        return 'Not enough disk space available.';
      case NativeRenderingErrorType.networkError:
        return 'Network error occurred during rendering.';
      case NativeRenderingErrorType.invalidArgument:
        return 'Invalid parameters provided for rendering.';
      case NativeRenderingErrorType.unsupportedOperation:
        return 'This operation is not supported on your device.';
      default:
        return 'An unexpected error occurred during document rendering.';
    }
  }

  @override
  String toString() {
    return 'NativeRenderingError(type: $type, message: $message, isRecoverable: $isRecoverable)';
  }
}

/// Types of native rendering errors
enum NativeRenderingErrorType {
  fileNotFound,
  permissionDenied,
  corruptedFile,
  memoryError,
  libraryNotAvailable,
  renderingFailed,
  diskFull,
  networkError,
  invalidArgument,
  unsupportedOperation,
  fileSystemError,
  nativeRenderingError,
  unknown,
}

/// Extension methods for error handling
extension NativeRenderingErrorTypeExtension on NativeRenderingErrorType {
  /// Get the severity level of the error
  ErrorSeverity get severity {
    switch (this) {
      case NativeRenderingErrorType.fileNotFound:
      case NativeRenderingErrorType.permissionDenied:
      case NativeRenderingErrorType.corruptedFile:
      case NativeRenderingErrorType.unsupportedOperation:
        return ErrorSeverity.high;
      
      case NativeRenderingErrorType.memoryError:
      case NativeRenderingErrorType.diskFull:
      case NativeRenderingErrorType.renderingFailed:
        return ErrorSeverity.medium;
      
      case NativeRenderingErrorType.libraryNotAvailable:
      case NativeRenderingErrorType.networkError:
        return ErrorSeverity.low;
      
      default:
        return ErrorSeverity.medium;
    }
  }

  /// Check if the error should be logged
  bool get shouldLog {
    switch (this) {
      case NativeRenderingErrorType.libraryNotAvailable:
        return false; // Expected in some environments
      default:
        return true;
    }
  }
}

/// Error severity levels
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}