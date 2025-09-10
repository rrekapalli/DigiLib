import 'package:json_annotation/json_annotation.dart';

part 'api_error.g.dart';

@JsonSerializable()
class ApiError {
  final String message;
  final String? code;
  final int? status;
  final Map<String, dynamic>? details;
  final DateTime timestamp;

  const ApiError({
    required this.message,
    this.code,
    this.status,
    this.details,
    required this.timestamp,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) => _$ApiErrorFromJson(json);
  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);

  ApiError copyWith({
    String? message,
    String? code,
    int? status,
    Map<String, dynamic>? details,
    DateTime? timestamp,
  }) {
    return ApiError(
      message: message ?? this.message,
      code: code ?? this.code,
      status: status ?? this.status,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiError &&
        other.message == message &&
        other.code == code &&
        other.status == status &&
        other.details == details &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      message,
      code,
      status,
      details,
      timestamp,
    );
  }

  @override
  String toString() {
    return 'ApiError(message: $message, code: $code, status: $status, details: $details, timestamp: $timestamp)';
  }
}

class ApiException implements Exception {
  final ApiError error;
  final String? originalMessage;

  const ApiException(this.error, [this.originalMessage]);

  @override
  String toString() {
    return 'ApiException: ${error.message}${originalMessage != null ? ' (Original: $originalMessage)' : ''}';
  }
}