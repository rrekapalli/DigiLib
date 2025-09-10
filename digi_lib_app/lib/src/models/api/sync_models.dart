import 'package:json_annotation/json_annotation.dart';

part 'sync_models.g.dart';

@JsonSerializable()
class SyncChange {
  @JsonKey(name: 'entity_type')
  final String entityType; // document, page, bookmark, comment, tag, reading_progress
  @JsonKey(name: 'entity_id')
  final String entityId;
  final String operation; // create, update, delete
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const SyncChange({
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.data,
    required this.timestamp,
  });

  factory SyncChange.fromJson(Map<String, dynamic> json) => _$SyncChangeFromJson(json);
  Map<String, dynamic> toJson() => _$SyncChangeToJson(this);

  SyncChange copyWith({
    String? entityType,
    String? entityId,
    String? operation,
    Map<String, dynamic>? data,
    DateTime? timestamp,
  }) {
    return SyncChange(
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncChange &&
        other.entityType == entityType &&
        other.entityId == entityId &&
        other.operation == operation &&
        other.data == data &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      entityType,
      entityId,
      operation,
      data,
      timestamp,
    );
  }

  @override
  String toString() {
    return 'SyncChange(entityType: $entityType, entityId: $entityId, operation: $operation, data: $data, timestamp: $timestamp)';
  }
}

@JsonSerializable()
class SyncManifest {
  final DateTime timestamp;
  final List<SyncChange> changes;
  final String checksum;

  const SyncManifest({
    required this.timestamp,
    required this.changes,
    required this.checksum,
  });

  factory SyncManifest.fromJson(Map<String, dynamic> json) => _$SyncManifestFromJson(json);
  Map<String, dynamic> toJson() => _$SyncManifestToJson(this);

  SyncManifest copyWith({
    DateTime? timestamp,
    List<SyncChange>? changes,
    String? checksum,
  }) {
    return SyncManifest(
      timestamp: timestamp ?? this.timestamp,
      changes: changes ?? this.changes,
      checksum: checksum ?? this.checksum,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncManifest &&
        other.timestamp == timestamp &&
        other.changes == changes &&
        other.checksum == checksum;
  }

  @override
  int get hashCode {
    return Object.hash(
      timestamp,
      changes,
      checksum,
    );
  }

  @override
  String toString() {
    return 'SyncManifest(timestamp: $timestamp, changes: $changes, checksum: $checksum)';
  }
}

@JsonSerializable()
class SyncPushRequest {
  final List<SyncChange> changes;
  @JsonKey(name: 'client_timestamp')
  final DateTime clientTimestamp;

  const SyncPushRequest({
    required this.changes,
    required this.clientTimestamp,
  });

  factory SyncPushRequest.fromJson(Map<String, dynamic> json) => _$SyncPushRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SyncPushRequestToJson(this);

  SyncPushRequest copyWith({
    List<SyncChange>? changes,
    DateTime? clientTimestamp,
  }) {
    return SyncPushRequest(
      changes: changes ?? this.changes,
      clientTimestamp: clientTimestamp ?? this.clientTimestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncPushRequest &&
        other.changes == changes &&
        other.clientTimestamp == clientTimestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      changes,
      clientTimestamp,
    );
  }

  @override
  String toString() {
    return 'SyncPushRequest(changes: $changes, clientTimestamp: $clientTimestamp)';
  }
}

@JsonSerializable()
class SyncConflict {
  @JsonKey(name: 'entity_id')
  final String entityId;
  @JsonKey(name: 'entity_type')
  final String entityType;
  @JsonKey(name: 'client_version')
  final Map<String, dynamic> clientVersion;
  @JsonKey(name: 'server_version')
  final Map<String, dynamic> serverVersion;
  final String resolution; // server_wins, client_wins, merge_required

  const SyncConflict({
    required this.entityId,
    required this.entityType,
    required this.clientVersion,
    required this.serverVersion,
    required this.resolution,
  });

  factory SyncConflict.fromJson(Map<String, dynamic> json) => _$SyncConflictFromJson(json);
  Map<String, dynamic> toJson() => _$SyncConflictToJson(this);

  SyncConflict copyWith({
    String? entityId,
    String? entityType,
    Map<String, dynamic>? clientVersion,
    Map<String, dynamic>? serverVersion,
    String? resolution,
  }) {
    return SyncConflict(
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      clientVersion: clientVersion ?? this.clientVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      resolution: resolution ?? this.resolution,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncConflict &&
        other.entityId == entityId &&
        other.entityType == entityType &&
        other.clientVersion == clientVersion &&
        other.serverVersion == serverVersion &&
        other.resolution == resolution;
  }

  @override
  int get hashCode {
    return Object.hash(
      entityId,
      entityType,
      clientVersion,
      serverVersion,
      resolution,
    );
  }

  @override
  String toString() {
    return 'SyncConflict(entityId: $entityId, entityType: $entityType, clientVersion: $clientVersion, serverVersion: $serverVersion, resolution: $resolution)';
  }
}

@JsonSerializable()
class SyncPushResponse {
  @JsonKey(name: 'accepted_changes')
  final List<String> acceptedChanges;
  final List<SyncConflict> conflicts;
  @JsonKey(name: 'server_timestamp')
  final DateTime serverTimestamp;

  const SyncPushResponse({
    required this.acceptedChanges,
    required this.conflicts,
    required this.serverTimestamp,
  });

  factory SyncPushResponse.fromJson(Map<String, dynamic> json) => _$SyncPushResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SyncPushResponseToJson(this);

  SyncPushResponse copyWith({
    List<String>? acceptedChanges,
    List<SyncConflict>? conflicts,
    DateTime? serverTimestamp,
  }) {
    return SyncPushResponse(
      acceptedChanges: acceptedChanges ?? this.acceptedChanges,
      conflicts: conflicts ?? this.conflicts,
      serverTimestamp: serverTimestamp ?? this.serverTimestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncPushResponse &&
        other.acceptedChanges == acceptedChanges &&
        other.conflicts == conflicts &&
        other.serverTimestamp == serverTimestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      acceptedChanges,
      conflicts,
      serverTimestamp,
    );
  }

  @override
  String toString() {
    return 'SyncPushResponse(acceptedChanges: $acceptedChanges, conflicts: $conflicts, serverTimestamp: $serverTimestamp)';
  }
}