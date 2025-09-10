import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/entities/share.dart';
import '../models/api/create_share_request.dart';
import '../database/repositories/share_repository.dart';
import '../network/connectivity_service.dart';
import 'share_api_service.dart';
import 'job_queue_service.dart';

/// Exception thrown when share operations fail
class ShareException implements Exception {
  final String message;
  final String? code;
  final Exception? cause;

  const ShareException(this.message, {this.code, this.cause});

  @override
  String toString() => 'ShareException: $message';
}

/// Service for managing shares with API integration, local caching, and offline support
class ShareService {
  final ShareApiService _apiService;
  final ShareRepository _repository;
  final JobQueueService _jobQueueService;
  final ConnectivityService _connectivityService;
  final Uuid _uuid = const Uuid();

  // Stream controllers for real-time updates
  final StreamController<List<Share>> _sharesController = StreamController<List<Share>>.broadcast();
  final StreamController<ShareEvent> _shareEventsController = StreamController<ShareEvent>.broadcast();

  ShareService({
    required ShareApiService apiService,
    required ShareRepository repository,
    required JobQueueService jobQueueService,
    required ConnectivityService connectivityService,
  }) : _apiService = apiService,
       _repository = repository,
       _jobQueueService = jobQueueService,
       _connectivityService = connectivityService;

  /// Stream of share lists (for UI updates)
  Stream<List<Share>> get sharesStream => _sharesController.stream;

  /// Stream of share events (create, update, delete)
  Stream<ShareEvent> get shareEventsStream => _shareEventsController.stream;

  /// Create a new share
  Future<Share> createShare(CreateShareRequest request, String ownerId) async {
    try {
      // Validate permission
      if (!_isValidPermission(request.permission)) {
        throw ShareException('Invalid permission level', code: 'INVALID_PERMISSION');
      }

      // Create share with local ID
      final share = Share(
        id: _uuid.v4(),
        subjectId: request.subjectId,
        subjectType: request.subjectType,
        ownerId: ownerId,
        granteeEmail: request.granteeEmail,
        permission: request.permission,
        createdAt: DateTime.now(),
      );

      // Save to local database immediately
      await _repository.insertShare(share);

      // If online, try to sync with server
      if (await _connectivityService.hasConnectivity()) {
        try {
          final serverShare = await _apiService.createShare(request);
          
          // Update local share with server ID and mark as synced
          final updatedShare = share.copyWith(id: serverShare.id);
          await _repository.updateShare(updatedShare);
          await _repository.markShareAsSynced(serverShare.id);
          
          _shareEventsController.add(ShareEvent.created(updatedShare));
          return updatedShare;
        } catch (e) {
          // If server request fails, queue for offline processing
          await _jobQueueService.addJob(JobType.createShare, {
            'share_id': share.id,
            'subject_id': request.subjectId,
            'subject_type': request.subjectType.name,
            'owner_id': ownerId,
            'grantee_email': request.granteeEmail,
            'permission': request.permission.name,
          });
        }
      } else {
        // Queue for offline processing
        await _jobQueueService.addJob(JobType.createShare, {
          'share_id': share.id,
          'subject_id': request.subjectId,
          'subject_type': request.subjectType.name,
          'owner_id': ownerId,
          'grantee_email': request.granteeEmail,
          'permission': request.permission.name,
        });
      }

      _shareEventsController.add(ShareEvent.created(share));
      return share;
    } catch (e) {
      throw ShareException('Failed to create share: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get all shares owned by a user
  Future<List<Share>> getShares(String ownerId) async {
    try {
      // Always return local data first for immediate UI response
      final localShares = await _repository.getSharesByOwnerId(ownerId);
      
      // If online, try to sync with server
      if (await _connectivityService.hasConnectivity()) {
        try {
          final serverShares = await _apiService.getShares();
          
          // Update local cache with server data
          await _syncSharesToLocal(serverShares);
          
          // Return updated local data
          final updatedShares = await _repository.getSharesByOwnerId(ownerId);
          _sharesController.add(updatedShares);
          return updatedShares;
        } catch (e) {
          // If server request fails, continue with local data
          // Log the error but don't throw to maintain offline functionality
        }
      }
      
      _sharesController.add(localShares);
      return localShares;
    } catch (e) {
      throw ShareException('Failed to get shares: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get all shares where user is the grantee
  Future<List<Share>> getSharedWithMe(String userEmail) async {
    try {
      // Always return local data first for immediate UI response
      final localShares = await _repository.getSharedWithUser(userEmail);
      
      // If online, try to sync with server
      if (await _connectivityService.hasConnectivity()) {
        try {
          final serverShares = await _apiService.getSharedWithMe();
          
          // Update local cache with server data
          await _syncSharesToLocal(serverShares);
          
          // Return updated local data
          final updatedShares = await _repository.getSharedWithUser(userEmail);
          _sharesController.add(updatedShares);
          return updatedShares;
        } catch (e) {
          // If server request fails, continue with local data
          // Log the error but don't throw to maintain offline functionality
        }
      }
      
      _sharesController.add(localShares);
      return localShares;
    } catch (e) {
      throw ShareException('Failed to get shared documents: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Update share permission
  Future<Share> updateSharePermission(String shareId, SharePermission permission) async {
    try {
      // Validate permission
      if (!_isValidPermission(permission)) {
        throw ShareException('Invalid permission level', code: 'INVALID_PERMISSION');
      }

      // Get current share from local database
      final currentShare = await _repository.getShareById(shareId);
      if (currentShare == null) {
        throw ShareException('Share not found', code: 'NOT_FOUND');
      }

      // Create updated share
      final updatedShare = currentShare.copyWith(permission: permission);
      
      // Update local database immediately
      await _repository.updateShare(updatedShare);
      await _repository.markShareAsUnsynced(shareId);

      // If online, try to sync with server
      if (await _connectivityService.hasConnectivity()) {
        try {
          final serverShare = await _apiService.updateSharePermission(shareId, permission);
          
          // Mark as synced
          await _repository.markShareAsSynced(shareId);
          
          _shareEventsController.add(ShareEvent.updated(serverShare));
          return serverShare;
        } catch (e) {
          // If server request fails, queue for offline processing
          await _jobQueueService.addJob(JobType.updateShare, {
            'share_id': shareId,
            'permission': permission.name,
          });
        }
      } else {
        // Queue for offline processing
        await _jobQueueService.addJob(JobType.updateShare, {
          'share_id': shareId,
          'permission': permission.name,
        });
      }

      _shareEventsController.add(ShareEvent.updated(updatedShare));
      return updatedShare;
    } catch (e) {
      throw ShareException('Failed to update share permission: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Delete a share
  Future<void> deleteShare(String shareId) async {
    try {
      // Get share before deletion for event notification
      final share = await _repository.getShareById(shareId);
      
      // Delete from local database immediately
      await _repository.deleteShare(shareId);

      // If online, try to sync with server
      if (await _connectivityService.hasConnectivity()) {
        try {
          await _apiService.deleteShare(shareId);
        } catch (e) {
          // If server request fails, queue for offline processing
          await _jobQueueService.addJob(JobType.deleteShare, {
            'share_id': shareId,
          });
        }
      } else {
        // Queue for offline processing
        await _jobQueueService.addJob(JobType.deleteShare, {
          'share_id': shareId,
        });
      }

      if (share != null) {
        _shareEventsController.add(ShareEvent.deleted(share));
      }
    } catch (e) {
      throw ShareException('Failed to delete share: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get shares for a specific subject (document or folder)
  Future<List<Share>> getSharesBySubject(String subjectId) async {
    try {
      // Always return local data first for immediate UI response
      final localShares = await _repository.getSharesBySubjectId(subjectId);
      
      // If online, try to sync with server
      if (await _connectivityService.hasConnectivity()) {
        try {
          final serverShares = await _apiService.getSharesBySubject(subjectId);
          
          // Update local cache with server data
          await _syncSharesToLocal(serverShares);
          
          // Return updated local data
          final updatedShares = await _repository.getSharesBySubjectId(subjectId);
          return updatedShares;
        } catch (e) {
          // If server request fails, continue with local data
          // Log the error but don't throw to maintain offline functionality
        }
      }
      
      return localShares;
    } catch (e) {
      throw ShareException('Failed to get shares for subject: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Check if a subject is shared with a specific user
  Future<bool> isSharedWithUser(String subjectId, String userEmail) async {
    try {
      return await _repository.isSharedWithUser(subjectId, userEmail);
    } catch (e) {
      throw ShareException('Failed to check share status: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get share permission for a user on a subject
  Future<SharePermission?> getSharePermission(String subjectId, String userEmail) async {
    try {
      return await _repository.getSharePermission(subjectId, userEmail);
    } catch (e) {
      throw ShareException('Failed to get share permission: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get shares count for a subject
  Future<int> getSharesCount(String subjectId) async {
    try {
      return await _repository.getSharesCountBySubjectId(subjectId);
    } catch (e) {
      throw ShareException('Failed to get shares count: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Validate access control - check if user has required permission
  Future<bool> hasPermission(String subjectId, String userEmail, SharePermission requiredPermission) async {
    try {
      final userPermission = await getSharePermission(subjectId, userEmail);
      if (userPermission == null) return false;
      
      // Permission hierarchy: full > comment > view
      switch (requiredPermission) {
        case SharePermission.view:
          return true; // All permissions include view
        case SharePermission.comment:
          return userPermission == SharePermission.comment || userPermission == SharePermission.full;
        case SharePermission.full:
          return userPermission == SharePermission.full;
      }
    } catch (e) {
      return false; // Deny access on error
    }
  }

  /// Process offline share actions
  Future<void> processOfflineActions() async {
    if (!await _connectivityService.hasConnectivity()) {
      return; // Skip if offline
    }

    try {
      final pendingJobs = await _jobQueueService.getPendingJobs();
      final shareJobs = pendingJobs.where((job) => 
        job.type == JobType.createShare ||
        job.type == JobType.updateShare ||
        job.type == JobType.deleteShare
      ).toList();

      for (final job in shareJobs) {
        try {
          await _jobQueueService.updateJobStatus(job.id, JobStatus.processing);
          
          switch (job.type) {
            case JobType.createShare:
              await _processCreateShareJob(job);
              break;
            case JobType.updateShare:
              await _processUpdateShareJob(job);
              break;
            case JobType.deleteShare:
              await _processDeleteShareJob(job);
              break;
            default:
              continue;
          }
          
          await _jobQueueService.completeJob(job.id);
        } catch (e) {
          await _jobQueueService.incrementJobAttempts(job.id, error: e.toString());
          
          // Fail job after 3 attempts
          if (job.attempts >= 2) {
            await _jobQueueService.failJob(job.id, 'Max attempts reached: ${e.toString()}');
          }
        }
      }
    } catch (e) {
      // Log error but don't throw to avoid breaking sync process
    }
  }

  /// Validate permission level
  bool _isValidPermission(SharePermission permission) {
    return SharePermission.values.contains(permission);
  }

  /// Sync server shares to local database
  Future<void> _syncSharesToLocal(List<Share> serverShares) async {
    for (final share in serverShares) {
      await _repository.insertShare(share);
      await _repository.markShareAsSynced(share.id);
    }
  }

  /// Process create share job
  Future<void> _processCreateShareJob(Job job) async {
    final payload = job.payload;
    final request = CreateShareRequest(
      subjectId: payload['subject_id'] as String,
      subjectType: ShareSubjectType.values.firstWhere((e) => e.name == payload['subject_type']),
      granteeEmail: payload['grantee_email'] as String,
      permission: SharePermission.values.firstWhere((e) => e.name == payload['permission']),
    );
    
    final serverShare = await _apiService.createShare(request);
    
    // Update local share with server ID
    final localShareId = payload['share_id'] as String;
    await _repository.deleteShare(localShareId); // Remove old local share
    await _repository.insertShare(serverShare);
    await _repository.markShareAsSynced(serverShare.id);
  }

  /// Process update share job
  Future<void> _processUpdateShareJob(Job job) async {
    final payload = job.payload;
    final permission = SharePermission.values.firstWhere((e) => e.name == payload['permission']);
    
    await _apiService.updateSharePermission(payload['share_id'] as String, permission);
    await _repository.markShareAsSynced(payload['share_id'] as String);
  }

  /// Process delete share job
  Future<void> _processDeleteShareJob(Job job) async {
    final payload = job.payload;
    await _apiService.deleteShare(payload['share_id'] as String);
    // Local share should already be deleted
  }

  /// Dispose resources
  void dispose() {
    _sharesController.close();
    _shareEventsController.close();
  }
}

/// Event types for share operations
enum ShareEventType { created, updated, deleted }

/// Event model for share operations
class ShareEvent {
  final ShareEventType type;
  final Share share;
  final DateTime timestamp;

  ShareEvent._(this.type, this.share) : timestamp = DateTime.now();

  factory ShareEvent.created(Share share) => ShareEvent._(ShareEventType.created, share);
  factory ShareEvent.updated(Share share) => ShareEvent._(ShareEventType.updated, share);
  factory ShareEvent.deleted(Share share) => ShareEvent._(ShareEventType.deleted, share);
}