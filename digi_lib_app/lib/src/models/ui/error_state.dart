import 'package:flutter/foundation.dart';
import '../api/api_error.dart';

/// Represents different types of errors that can occur in the app
enum ErrorType {
  network,
  authentication,
  fileSystem,
  nativeWorker,
  syncConflict,
  validation,
  permission,
  unknown,
}

/// Represents the severity of an error
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// Represents an error state with contextual information
@immutable
class ErrorState {
  final String message;
  final ErrorType type;
  final ErrorSeverity severity;
  final String? code;
  final Map<String, dynamic>? details;
  final DateTime timestamp;
  final StackTrace? stackTrace;
  final String? context; // Where the error occurred
  final List<ErrorAction> actions;

  const ErrorState({
    required this.message,
    required this.type,
    this.severity = ErrorSeverity.error,
    this.code,
    this.details,
    required this.timestamp,
    this.stackTrace,
    this.context,
    this.actions = const [],
  });

  factory ErrorState.fromApiException(
    ApiException exception, {
    String? context,
    List<ErrorAction> actions = const [],
  }) {
    return ErrorState(
      message: exception.error.message,
      type: _getErrorTypeFromApiError(exception.error),
      severity: _getSeverityFromStatus(exception.error.status),
      code: exception.error.code,
      details: exception.error.details,
      timestamp: exception.error.timestamp,
      context: context,
      actions: actions,
    );
  }

  factory ErrorState.network({
    required String message,
    String? code,
    String? context,
    List<ErrorAction> actions = const [],
  }) {
    return ErrorState(
      message: message,
      type: ErrorType.network,
      severity: ErrorSeverity.warning,
      code: code,
      timestamp: DateTime.now(),
      context: context,
      actions: actions,
    );
  }

  factory ErrorState.fileSystem({
    required String message,
    String? code,
    String? context,
    List<ErrorAction> actions = const [],
  }) {
    return ErrorState(
      message: message,
      type: ErrorType.fileSystem,
      severity: ErrorSeverity.error,
      code: code,
      timestamp: DateTime.now(),
      context: context,
      actions: actions,
    );
  }

  factory ErrorState.nativeWorker({
    required String message,
    String? code,
    String? context,
    List<ErrorAction> actions = const [],
  }) {
    return ErrorState(
      message: message,
      type: ErrorType.nativeWorker,
      severity: ErrorSeverity.error,
      code: code,
      timestamp: DateTime.now(),
      context: context,
      actions: actions,
    );
  }

  factory ErrorState.syncConflict({
    required String message,
    String? code,
    String? context,
    List<ErrorAction> actions = const [],
  }) {
    return ErrorState(
      message: message,
      type: ErrorType.syncConflict,
      severity: ErrorSeverity.warning,
      code: code,
      timestamp: DateTime.now(),
      context: context,
      actions: actions,
    );
  }

  factory ErrorState.validation({
    required String message,
    String? code,
    String? context,
    List<ErrorAction> actions = const [],
  }) {
    return ErrorState(
      message: message,
      type: ErrorType.validation,
      severity: ErrorSeverity.warning,
      code: code,
      timestamp: DateTime.now(),
      context: context,
      actions: actions,
    );
  }

  factory ErrorState.permission({
    required String message,
    String? code,
    String? context,
    List<ErrorAction> actions = const [],
  }) {
    return ErrorState(
      message: message,
      type: ErrorType.permission,
      severity: ErrorSeverity.error,
      code: code,
      timestamp: DateTime.now(),
      context: context,
      actions: actions,
    );
  }

  static ErrorType _getErrorTypeFromApiError(ApiError error) {
    if (error.status == 401 || error.status == 403) {
      return ErrorType.authentication;
    }
    if (error.status == 422) {
      return ErrorType.validation;
    }
    if (error.code?.contains('TIMEOUT') == true || 
        error.code?.contains('CONNECTION') == true) {
      return ErrorType.network;
    }
    return ErrorType.unknown;
  }

  static ErrorSeverity _getSeverityFromStatus(int? status) {
    if (status == null) return ErrorSeverity.error;
    if (status >= 500) return ErrorSeverity.critical;
    if (status >= 400) return ErrorSeverity.error;
    return ErrorSeverity.warning;
  }

  ErrorState copyWith({
    String? message,
    ErrorType? type,
    ErrorSeverity? severity,
    String? code,
    Map<String, dynamic>? details,
    DateTime? timestamp,
    StackTrace? stackTrace,
    String? context,
    List<ErrorAction>? actions,
  }) {
    return ErrorState(
      message: message ?? this.message,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      code: code ?? this.code,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
      actions: actions ?? this.actions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorState &&
        other.message == message &&
        other.type == type &&
        other.severity == severity &&
        other.code == code &&
        other.timestamp == timestamp &&
        other.context == context;
  }

  @override
  int get hashCode {
    return Object.hash(
      message,
      type,
      severity,
      code,
      timestamp,
      context,
    );
  }

  @override
  String toString() {
    return 'ErrorState(message: $message, type: $type, severity: $severity, code: $code, context: $context)';
  }
}

/// Represents an action that can be taken in response to an error
@immutable
class ErrorAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const ErrorAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorAction &&
        other.label == label &&
        other.isPrimary == isPrimary;
  }

  @override
  int get hashCode {
    return Object.hash(label, isPrimary);
  }
}

/// Exception classes for different error types
class NetworkException implements Exception {
  final String message;
  final String? code;
  final Object? originalError;

  const NetworkException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'NetworkException: $message';
}

class FileSystemException implements Exception {
  final String message;
  final String? path;
  final Object? originalError;

  const FileSystemException(this.message, {this.path, this.originalError});

  @override
  String toString() => 'FileSystemException: $message';
}

class NativeWorkerException implements Exception {
  final String message;
  final String? operation;
  final Object? originalError;

  const NativeWorkerException(this.message, {this.operation, this.originalError});

  @override
  String toString() => 'NativeWorkerException: $message';
}

class SyncConflictException implements Exception {
  final String message;
  final String? entityId;
  final String? entityType;
  final Object? originalError;

  const SyncConflictException(this.message, {this.entityId, this.entityType, this.originalError});

  @override
  String toString() => 'SyncConflictException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? fieldErrors;
  final Object? originalError;

  const ValidationException(this.message, {this.fieldErrors, this.originalError});

  @override
  String toString() => 'ValidationException: $message';
}

class PermissionException implements Exception {
  final String message;
  final String? permission;
  final Object? originalError;

  const PermissionException(this.message, {this.permission, this.originalError});

  @override
  String toString() => 'PermissionException: $message';
}