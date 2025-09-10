import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/api/sync_models.dart';
import 'job_queue_service.dart';

/// Information about a sync conflict that needs user resolution
class SyncConflictInfo {
  final String id;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> localVersion;
  final Map<String, dynamic> serverVersion;
  final DateTime conflictTime;
  final String? description;

  const SyncConflictInfo({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.localVersion,
    required this.serverVersion,
    required this.conflictTime,
    this.description,
  });

  /// Get a human-readable description of the conflict
  String get displayDescription {
    if (description != null) return description!;

    switch (entityType) {
      case 'bookmark':
        return 'Bookmark conflict: Different notes or page numbers';
      case 'comment':
        return 'Comment conflict: Different content or positioning';
      case 'reading_progress':
        return 'Reading progress conflict: Different last read pages';
      case 'tag':
        return 'Tag conflict: Different tag names or properties';
      case 'document_tag':
        return 'Document tagging conflict: Different tag assignments';
      case 'share':
        return 'Sharing conflict: Different permissions or settings';
      default:
        return 'Data conflict: Local and server versions differ';
    }
  }

  /// Get the entity name for display
  String get entityDisplayName {
    switch (entityType) {
      case 'bookmark':
        return localVersion['note']?.toString() ?? 'Bookmark';
      case 'comment':
        return 'Comment: ${localVersion['content']?.toString().substring(0, 50) ?? 'Unknown'}...';
      case 'reading_progress':
        return 'Reading Progress';
      case 'tag':
        return 'Tag: ${localVersion['name'] ?? 'Unknown'}';
      case 'document_tag':
        return 'Document Tag Assignment';
      case 'share':
        return 'Share: ${localVersion['grantee_email'] ?? 'Unknown'}';
      default:
        return entityType;
    }
  }
}

/// Service for handling sync conflict resolution
class SyncConflictService {
  final JobQueueService _jobQueueService;
  final StreamController<List<SyncConflictInfo>> _conflictsController =
      StreamController<List<SyncConflictInfo>>.broadcast();

  List<SyncConflictInfo> _currentConflicts = [];

  SyncConflictService({required JobQueueService jobQueueService})
    : _jobQueueService = jobQueueService {
    _initializeConflictMonitoring();
  }

  /// Stream of current sync conflicts
  Stream<List<SyncConflictInfo>> get conflictsStream =>
      _conflictsController.stream;

  /// Get current list of conflicts
  List<SyncConflictInfo> get currentConflicts =>
      List.unmodifiable(_currentConflicts);

  /// Check if there are any unresolved conflicts
  bool get hasConflicts => _currentConflicts.isNotEmpty;

  /// Initialize conflict monitoring
  void _initializeConflictMonitoring() {
    // Monitor job queue for conflicts
    _jobQueueService.statusStream.listen((_) {
      _refreshConflicts();
    });

    // Initial load
    _refreshConflicts();
  }

  /// Refresh the list of conflicts from the job queue
  Future<void> _refreshConflicts() async {
    try {
      final conflictedJobs = await _jobQueueService.getConflictedJobs();

      _currentConflicts = conflictedJobs
          .map(
            (job) => SyncConflictInfo(
              id: job.id,
              entityType: _getEntityTypeFromJobType(job.type),
              entityId: job.payload['id'] ?? job.payload['entity_id'] ?? job.id,
              localVersion: job.payload,
              serverVersion: {}, // Would be populated from actual conflict data
              conflictTime: job.createdAt,
              description: job.lastError,
            ),
          )
          .toList();

      _conflictsController.add(_currentConflicts);
    } catch (e) {
      debugPrint('Error refreshing conflicts: $e');
    }
  }

  /// Add a new conflict from sync response
  void addConflict(SyncConflict conflict) {
    final conflictInfo = SyncConflictInfo(
      id: '${conflict.entityType}_${conflict.entityId}',
      entityType: conflict.entityType,
      entityId: conflict.entityId,
      localVersion: conflict.clientVersion,
      serverVersion: conflict.serverVersion,
      conflictTime: DateTime.now(),
    );

    _currentConflicts.add(conflictInfo);
    _conflictsController.add(_currentConflicts);
  }

  /// Resolve a conflict with the specified resolution strategy
  Future<void> resolveConflict(
    String conflictId,
    ConflictResolution resolution,
  ) async {
    try {
      // Find the conflict
      final conflict = _currentConflicts.firstWhere(
        (c) => c.id == conflictId,
        orElse: () => throw ArgumentError('Conflict not found: $conflictId'),
      );

      // Resolve in job queue
      await _jobQueueService.resolveConflict(conflictId, resolution);

      // Remove from current conflicts
      _currentConflicts.removeWhere((c) => c.id == conflictId);
      _conflictsController.add(_currentConflicts);

      debugPrint('Resolved conflict $conflictId with strategy: $resolution');
    } catch (e) {
      debugPrint('Error resolving conflict $conflictId: $e');
      rethrow;
    }
  }

  /// Resolve all conflicts with the same strategy
  Future<void> resolveAllConflicts(ConflictResolution resolution) async {
    final conflictIds = _currentConflicts.map((c) => c.id).toList();

    for (final conflictId in conflictIds) {
      try {
        await resolveConflict(conflictId, resolution);
      } catch (e) {
        debugPrint('Error resolving conflict $conflictId: $e');
        // Continue with other conflicts
      }
    }
  }

  /// Get suggested resolution for a conflict based on entity type and data
  ConflictResolution getSuggestedResolution(SyncConflictInfo conflict) {
    switch (conflict.entityType) {
      case 'reading_progress':
        // For reading progress, prefer the higher page number
        final localPage = conflict.localVersion['last_page'] as int? ?? 0;
        final serverPage = conflict.serverVersion['last_page'] as int? ?? 0;
        return localPage > serverPage
            ? ConflictResolution.useLocal
            : ConflictResolution.useServer;

      case 'bookmark':
      case 'comment':
        // For user-generated content, prefer local changes
        return ConflictResolution.useLocal;

      case 'tag':
      case 'document_tag':
        // For organizational data, prefer server version
        return ConflictResolution.useServer;

      case 'share':
        // For sharing, prefer more restrictive permissions (server)
        return ConflictResolution.useServer;

      default:
        // Default to server version for unknown types
        return ConflictResolution.useServer;
    }
  }

  /// Get conflict statistics
  Map<String, int> getConflictStatistics() {
    final stats = <String, int>{};

    for (final conflict in _currentConflicts) {
      stats[conflict.entityType] = (stats[conflict.entityType] ?? 0) + 1;
    }

    return stats;
  }

  /// Clear all resolved conflicts from memory
  void clearResolvedConflicts() {
    _currentConflicts.clear();
    _conflictsController.add(_currentConflicts);
  }

  /// Get entity type from job type
  String _getEntityTypeFromJobType(JobType jobType) {
    switch (jobType) {
      case JobType.createBookmark:
      case JobType.updateBookmark:
      case JobType.deleteBookmark:
        return 'bookmark';
      case JobType.createComment:
      case JobType.updateComment:
      case JobType.deleteComment:
        return 'comment';
      case JobType.updateReadingProgress:
      case JobType.deleteReadingProgress:
        return 'reading_progress';
      case JobType.createTag:
      case JobType.deleteTag:
        return 'tag';
      case JobType.addTagToDocument:
      case JobType.removeTagFromDocument:
        return 'document_tag';
      case JobType.createShare:
      case JobType.updateShare:
      case JobType.deleteShare:
        return 'share';
      case JobType.createLibrary:
      case JobType.deleteLibrary:
      case JobType.scanLibrary:
        return 'library';
    }
  }

  /// Dispose resources
  void dispose() {
    _conflictsController.close();
  }
}
