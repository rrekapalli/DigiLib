import 'dart:async';
import '../models/entities/reading_progress.dart';
import '../database/repositories/reading_progress_repository.dart';
import '../network/connectivity_service.dart';
import 'reading_progress_api_service.dart';
import 'job_queue_service.dart';

/// Exception thrown when reading progress operations fail
class ReadingProgressException implements Exception {
  final String message;
  final String? code;
  final Exception? cause;

  const ReadingProgressException(this.message, {this.code, this.cause});

  @override
  String toString() => 'ReadingProgressException: $message';
}

/// Service for managing reading progress with API integration, local caching, and offline support
class ReadingProgressService {
  final ReadingProgressApiService _apiService;
  final ReadingProgressRepository _repository;
  final JobQueueService _jobQueueService;
  final ConnectivityService _connectivityService;

  // Stream controllers for real-time updates
  final StreamController<ReadingProgress> _progressController = StreamController<ReadingProgress>.broadcast();
  final StreamController<ReadingProgressEvent> _progressEventsController = StreamController<ReadingProgressEvent>.broadcast();

  // Auto-save configuration
  static const Duration _autoSaveDelay = Duration(seconds: 2);
  Timer? _autoSaveTimer;
  String? _pendingDocumentId;
  int? _pendingPage;
  String? _pendingUserId;

  ReadingProgressService({
    required ReadingProgressApiService apiService,
    required ReadingProgressRepository repository,
    required JobQueueService jobQueueService,
    required ConnectivityService connectivityService,
  }) : _apiService = apiService,
       _repository = repository,
       _jobQueueService = jobQueueService,
       _connectivityService = connectivityService;

  /// Stream of reading progress updates (for UI updates)
  Stream<ReadingProgress> get progressStream => _progressController.stream;

  /// Stream of reading progress events (update, delete)
  Stream<ReadingProgressEvent> get progressEventsStream => _progressEventsController.stream;

  /// Get reading progress for a specific document
  Future<ReadingProgress?> getReadingProgress(String userId, String documentId) async {
    try {
      // Always return local data first for immediate UI response
      final localProgress = await _repository.getReadingProgress(userId, documentId);
      
      // If online, try to sync with server
      if (_connectivityService.isConnected) {
        try {
          final serverProgress = await _apiService.getReadingProgress(documentId);
          
          if (serverProgress != null) {
            // Update local cache with server data if it's newer
            if (localProgress == null || serverProgress.updatedAt.isAfter(localProgress.updatedAt)) {
              await _repository.upsertReadingProgress(serverProgress);
              await _repository.markReadingProgressAsSynced(userId, documentId);
              return serverProgress;
            }
          }
        } catch (e) {
          // If server request fails, continue with local data
          // Log the error but don't throw to maintain offline functionality
        }
      }
      
      return localProgress;
    } catch (e) {
      throw ReadingProgressException('Failed to get reading progress: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Update reading progress immediately
  Future<ReadingProgress> updateReadingProgress(String userId, String documentId, int lastPage) async {
    try {
      // Create progress record
      final progress = ReadingProgress(
        userId: userId,
        docId: documentId,
        lastPage: lastPage,
        updatedAt: DateTime.now(),
      );

      // Save to local database immediately
      await _repository.upsertReadingProgress(progress);

      // If online, try to sync with server
      if (_connectivityService.isConnected) {
        try {
          final serverProgress = await _apiService.updateReadingProgress(documentId, lastPage);
          
          // Mark as synced
          await _repository.markReadingProgressAsSynced(userId, documentId);
          
          _progressController.add(serverProgress);
          _progressEventsController.add(ReadingProgressEvent.updated(serverProgress));
          return serverProgress;
        } catch (e) {
          // If server request fails, queue for offline processing
          await _jobQueueService.addJob(JobType.updateReadingProgress, {
            'user_id': userId,
            'document_id': documentId,
            'last_page': lastPage,
          });
        }
      } else {
        // Queue for offline processing
        await _jobQueueService.addJob(JobType.updateReadingProgress, {
          'user_id': userId,
          'document_id': documentId,
          'last_page': lastPage,
        });
      }

      _progressController.add(progress);
      _progressEventsController.add(ReadingProgressEvent.updated(progress));
      return progress;
    } catch (e) {
      throw ReadingProgressException('Failed to update reading progress: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Update reading progress with auto-save (debounced)
  /// This is useful for frequent page changes during reading
  void updateReadingProgressAutoSave(String userId, String documentId, int lastPage) {
    // Cancel previous timer
    _autoSaveTimer?.cancel();
    
    // Store pending update
    _pendingUserId = userId;
    _pendingDocumentId = documentId;
    _pendingPage = lastPage;
    
    // Set new timer
    _autoSaveTimer = Timer(_autoSaveDelay, () async {
      if (_pendingUserId != null && _pendingDocumentId != null && _pendingPage != null) {
        try {
          await updateReadingProgress(_pendingUserId!, _pendingDocumentId!, _pendingPage!);
        } catch (e) {
          // Log error but don't throw to avoid breaking reading experience
        } finally {
          _pendingUserId = null;
          _pendingDocumentId = null;
          _pendingPage = null;
        }
      }
    });
  }

  /// Force save any pending auto-save progress
  Future<void> flushAutoSave() async {
    _autoSaveTimer?.cancel();
    
    if (_pendingUserId != null && _pendingDocumentId != null && _pendingPage != null) {
      try {
        await updateReadingProgress(_pendingUserId!, _pendingDocumentId!, _pendingPage!);
      } finally {
        _pendingUserId = null;
        _pendingDocumentId = null;
        _pendingPage = null;
      }
    }
  }

  /// Delete reading progress for a document
  Future<void> deleteReadingProgress(String userId, String documentId) async {
    try {
      // Get progress before deletion for event notification
      final progress = await _repository.getReadingProgress(userId, documentId);
      
      // Delete from local database immediately
      await _repository.deleteReadingProgress(userId, documentId);

      // If online, try to sync with server
      if (_connectivityService.isConnected) {
        try {
          await _apiService.deleteReadingProgress(documentId);
        } catch (e) {
          // If server request fails, queue for offline processing
          await _jobQueueService.addJob(JobType.deleteReadingProgress, {
            'user_id': userId,
            'document_id': documentId,
          });
        }
      } else {
        // Queue for offline processing
        await _jobQueueService.addJob(JobType.deleteReadingProgress, {
          'user_id': userId,
          'document_id': documentId,
        });
      }

      if (progress != null) {
        _progressEventsController.add(ReadingProgressEvent.deleted(progress));
      }
    } catch (e) {
      throw ReadingProgressException('Failed to delete reading progress: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get recently read documents
  Future<List<ReadingProgress>> getRecentlyReadDocuments(String userId, {int limit = 10}) async {
    try {
      // Get local data first
      final localProgress = await _repository.getRecentlyReadDocuments(userId, limit: limit);
      
      // If online, try to get server data
      if (_connectivityService.isConnected) {
        try {
          final serverProgress = await _apiService.getRecentReadingProgress(limit: limit);
          
          // Merge and update local cache
          await _syncProgressToLocal(serverProgress);
          
          // Return updated local data
          return await _repository.getRecentlyReadDocuments(userId, limit: limit);
        } catch (e) {
          // If server request fails, return local data
        }
      }
      
      return localProgress;
    } catch (e) {
      throw ReadingProgressException('Failed to get recent documents: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get documents currently in progress
  Future<List<ReadingProgress>> getDocumentsInProgress(String userId) async {
    try {
      // Get local data first
      final localProgress = await _repository.getDocumentsInProgress(userId);
      
      // If online, try to get server data
      if (_connectivityService.isConnected) {
        try {
          final serverProgress = await _apiService.getInProgressDocuments();
          
          // Merge and update local cache
          await _syncProgressToLocal(serverProgress);
          
          // Return updated local data
          return await _repository.getDocumentsInProgress(userId);
        } catch (e) {
          // If server request fails, return local data
        }
      }
      
      return localProgress;
    } catch (e) {
      throw ReadingProgressException('Failed to get documents in progress: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get reading progress percentage
  Future<double?> getReadingProgressPercentage(String userId, String documentId, int totalPages) async {
    try {
      return await _repository.getReadingProgressPercentage(userId, documentId, totalPages);
    } catch (e) {
      throw ReadingProgressException('Failed to get reading progress percentage: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Check if document has been read
  Future<bool> hasReadingProgress(String userId, String documentId) async {
    try {
      return await _repository.hasReadingProgress(userId, documentId);
    } catch (e) {
      throw ReadingProgressException('Failed to check reading progress: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get reading statistics
  Future<ReadingStats?> getReadingStats() async {
    try {
      if (_connectivityService.isConnected) {
        return await _apiService.getReadingStats();
      }
      return null; // Stats require server data
    } catch (e) {
      throw ReadingProgressException('Failed to get reading stats: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Process offline reading progress actions
  Future<void> processOfflineActions() async {
    if (!_connectivityService.isConnected) {
      return; // Skip if offline
    }

    try {
      final pendingJobs = await _jobQueueService.getPendingJobs();
      final progressJobs = pendingJobs.where((job) => 
        job.type == JobType.updateReadingProgress ||
        job.type == JobType.deleteReadingProgress
      ).toList();

      for (final job in progressJobs) {
        try {
          await _jobQueueService.updateJobStatus(job.id, JobStatus.processing);
          
          switch (job.type) {
            case JobType.updateReadingProgress:
              await _processUpdateProgressJob(job);
              break;
            case JobType.deleteReadingProgress:
              await _processDeleteProgressJob(job);
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

  /// Sync server progress to local database
  Future<void> _syncProgressToLocal(List<ReadingProgress> serverProgress) async {
    await _repository.batchUpsertReadingProgress(serverProgress);
    
    for (final progress in serverProgress) {
      await _repository.markReadingProgressAsSynced(progress.userId, progress.docId);
    }
  }

  /// Process update reading progress job
  Future<void> _processUpdateProgressJob(Job job) async {
    final payload = job.payload;
    await _apiService.updateReadingProgress(
      payload['document_id'] as String,
      payload['last_page'] as int,
    );
    
    await _repository.markReadingProgressAsSynced(
      payload['user_id'] as String,
      payload['document_id'] as String,
    );
  }

  /// Process delete reading progress job
  Future<void> _processDeleteProgressJob(Job job) async {
    final payload = job.payload;
    await _apiService.deleteReadingProgress(payload['document_id'] as String);
    // Local progress should already be deleted
  }

  /// Dispose resources
  void dispose() {
    _autoSaveTimer?.cancel();
    _progressController.close();
    _progressEventsController.close();
  }
}

/// Event types for reading progress operations
enum ReadingProgressEventType { updated, deleted }

/// Event model for reading progress operations
class ReadingProgressEvent {
  final ReadingProgressEventType type;
  final ReadingProgress progress;
  final DateTime timestamp;

  ReadingProgressEvent._(this.type, this.progress) : timestamp = DateTime.now();

  factory ReadingProgressEvent.updated(ReadingProgress progress) => ReadingProgressEvent._(ReadingProgressEventType.updated, progress);
  factory ReadingProgressEvent.deleted(ReadingProgress progress) => ReadingProgressEvent._(ReadingProgressEventType.deleted, progress);
}