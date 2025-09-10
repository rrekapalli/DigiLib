import '../entities/share.dart';

/// Event for share operations
class ShareEvent {
  final ShareEventType type;
  final Share share;
  final DateTime timestamp;
  final String? error;

  const ShareEvent({
    required this.type,
    required this.share,
    required this.timestamp,
    this.error,
  });

  /// Factory constructor for created events
  factory ShareEvent.created(Share share) => ShareEvent(
    type: ShareEventType.created,
    share: share,
    timestamp: DateTime.now(),
  );

  /// Factory constructor for updated events
  factory ShareEvent.updated(Share share) => ShareEvent(
    type: ShareEventType.updated,
    share: share,
    timestamp: DateTime.now(),
  );

  /// Factory constructor for deleted events
  factory ShareEvent.deleted(Share share) => ShareEvent(
    type: ShareEventType.deleted,
    share: share,
    timestamp: DateTime.now(),
  );

  /// Check if event represents an error
  bool get isError => error != null;

  /// Check if event is successful
  bool get isSuccess => error == null;

  ShareEvent copyWith({
    ShareEventType? type,
    Share? share,
    DateTime? timestamp,
    String? error,
  }) {
    return ShareEvent(
      type: type ?? this.type,
      share: share ?? this.share,
      timestamp: timestamp ?? this.timestamp,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShareEvent &&
        other.type == type &&
        other.share == share &&
        other.timestamp == timestamp &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(type, share, timestamp, error);
  }

  @override
  String toString() {
    return 'ShareEvent(type: $type, share: ${share.id}, '
        'timestamp: $timestamp, error: $error)';
  }
}

/// Types of share events
enum ShareEventType { created, updated, deleted, permissionChanged, error }
