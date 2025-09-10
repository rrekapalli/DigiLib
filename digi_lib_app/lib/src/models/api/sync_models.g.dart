// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncChange _$SyncChangeFromJson(Map<String, dynamic> json) => SyncChange(
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      operation: json['operation'] as String,
      data: json['data'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$SyncChangeToJson(SyncChange instance) =>
    <String, dynamic>{
      'entity_type': instance.entityType,
      'entity_id': instance.entityId,
      'operation': instance.operation,
      'data': instance.data,
      'timestamp': instance.timestamp.toIso8601String(),
    };

SyncManifest _$SyncManifestFromJson(Map<String, dynamic> json) => SyncManifest(
      timestamp: DateTime.parse(json['timestamp'] as String),
      changes: (json['changes'] as List<dynamic>)
          .map((e) => SyncChange.fromJson(e as Map<String, dynamic>))
          .toList(),
      checksum: json['checksum'] as String,
    );

Map<String, dynamic> _$SyncManifestToJson(SyncManifest instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'changes': instance.changes,
      'checksum': instance.checksum,
    };

SyncPushRequest _$SyncPushRequestFromJson(Map<String, dynamic> json) =>
    SyncPushRequest(
      changes: (json['changes'] as List<dynamic>)
          .map((e) => SyncChange.fromJson(e as Map<String, dynamic>))
          .toList(),
      clientTimestamp: DateTime.parse(json['client_timestamp'] as String),
    );

Map<String, dynamic> _$SyncPushRequestToJson(SyncPushRequest instance) =>
    <String, dynamic>{
      'changes': instance.changes,
      'client_timestamp': instance.clientTimestamp.toIso8601String(),
    };

SyncConflict _$SyncConflictFromJson(Map<String, dynamic> json) => SyncConflict(
      entityId: json['entity_id'] as String,
      entityType: json['entity_type'] as String,
      clientVersion: json['client_version'] as Map<String, dynamic>,
      serverVersion: json['server_version'] as Map<String, dynamic>,
      resolution: json['resolution'] as String,
    );

Map<String, dynamic> _$SyncConflictToJson(SyncConflict instance) =>
    <String, dynamic>{
      'entity_id': instance.entityId,
      'entity_type': instance.entityType,
      'client_version': instance.clientVersion,
      'server_version': instance.serverVersion,
      'resolution': instance.resolution,
    };

SyncPushResponse _$SyncPushResponseFromJson(Map<String, dynamic> json) =>
    SyncPushResponse(
      acceptedChanges: (json['accepted_changes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      conflicts: (json['conflicts'] as List<dynamic>)
          .map((e) => SyncConflict.fromJson(e as Map<String, dynamic>))
          .toList(),
      serverTimestamp: DateTime.parse(json['server_timestamp'] as String),
    );

Map<String, dynamic> _$SyncPushResponseToJson(SyncPushResponse instance) =>
    <String, dynamic>{
      'accepted_changes': instance.acceptedChanges,
      'conflicts': instance.conflicts,
      'server_timestamp': instance.serverTimestamp.toIso8601String(),
    };
