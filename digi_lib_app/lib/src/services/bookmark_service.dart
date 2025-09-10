import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/entities/bookmark.dart';
import '../models/api/create_bookmark_request.dart';
import '../models/api/update_bookmark_request.dart';
import '../database/repositories/bookmark_repository.dart';
import '../network/connectivity_service.dart';
import 'bookmark_api_service.dart';
import 'job_queue_service.dart';

/// Exception thrown when bookmark operations fail
class BookmarkException implements Exception {
  final String message;
  final String? code;
  final Exception? cause;

  const BookmarkException(this.message, {this.code, this.cause});

  @override
  String toString() => 'BookmarkException: $message';
}

/// Service for managing bookmarks with API integration, local caching, and offline support
class BookmarkService {
  final BookmarkApiService _apiService;
  final BookmarkRepository _repository;
  final JobQueueService _jobQueueService;
  final ConnectivityService _connectivityService;
  final Uuid _uuid = const Uuid();

  // Stream controllers for real-time updates
  final StreamController<List<Bookmark>> _bookmarksController = StreamController<List<Bookmark>>.broadcast();
  final StreamController<BookmarkEvent> _bookmarkEventsController = StreamController<BookmarkEvent>.broadcast();

  BookmarkService({
    required BookmarkApiService apiService,
    required BookmarkRepository repository,
    required JobQueueService jobQueueService,
    required ConnectivityService connectivityService,
  }) : _apiService = apiService,
       _repository = repository,
       _jobQueueService = jobQueueService,
       _connectivityService = connectivityService;

  /// Stream of bookmark lists (for UI updates)
  Stream<List<Bookmark>> get bookmarksStream => _bookmarksController.stream;

  /// Stream of bookmark events (create, update, delete)
  Stream<BookmarkEvent> get bookmarkEventsStream => _bookmarkEventsController.stream;

  /// Get all bookmarks for a specific document
  Future<List<Bookmark>> getBookmarks(String documentId) async {
    try {
      // Always return local data first for immediate UI response
      final localBookmarks = await _repository.getBookmarksByDocumentId(documentId);
      
      // If online, try to sync with server
      if (_connectivityService.hasConnectivity()) {
        try {
          final serverBookmarks = await _apiService.getBookmarks(documentId);
          
          // Update local cache with server data
          await _syncBookmarksToLocal(serverBookmarks);
          
          // Return updated local data
          final updatedBookmarks = await _repository.getBookmarksByDocumentId(documentId);
          _bookmarksController.add(updatedBookmarks);
          return updatedBookmarks;
        } catch (e) {
          // If server request fails, continue with local data
          // Log the error but don't throw to maintain offline functionality
        }
      }
      
      _bookmarksController.add(localBookmarks);
      return localBookmarks;
    } catch (e) {
      throw BookmarkException('Failed to get bookmarks: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Add a new bookmark
  Future<Bookmark> addBookmark(String documentId, int pageNumber, String userId, {String? note}) async {
    try {
      // Create bookmark with local ID
      final bookmark = Bookmark(
        id: _uuid.v4(),
        userId: userId,
        docId: documentId,
        pageNumber: pageNumber,
        note: note,
        createdAt: DateTime.now(),
      );

      // Save to local database immediately
      await _repository.insertBookmark(bookmark);

      // If online, try to sync with server
      if (_connectivityService.hasConnectivity()) {
        try {
          final request = CreateBookmarkRequest(pageNumber: pageNumber, note: note);
          final serverBookmark = await _apiService.addBookmark(documentId, request);
          
          // Update local bookmark with server ID and mark as synced
          final updatedBookmark = bookmark.copyWith(id: serverBookmark.id);
          await _repository.updateBookmark(updatedBookmark);
          await _repository.markBookmarkAsSynced(serverBookmark.id);
          
          _bookmarkEventsController.add(BookmarkEvent.created(updatedBookmark));
          return updatedBookmark;
        } catch (e) {
          // If server request fails, queue for offline processing
          await _jobQueueService.addJob(JobType.createBookmark, {
            'bookmark_id': bookmark.id,
            'document_id': documentId,
            'page_number': pageNumber,
            'note': note,
            'user_id': userId,
          });
        }
      } else {
        // Queue for offline processing
        await _jobQueueService.addJob(JobType.createBookmark, {
          'bookmark_id': bookmark.id,
          'document_id': documentId,
          'page_number': pageNumber,
          'note': note,
          'user_id': userId,
        });
      }

      _bookmarkEventsController.add(BookmarkEvent.created(bookmark));
      return bookmark;
    } catch (e) {
      throw BookmarkException('Failed to add bookmark: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Update an existing bookmark
  Future<Bookmark> updateBookmark(String bookmarkId, {String? note}) async {
    try {
      // Get current bookmark from local database
      final currentBookmark = await _repository.getBookmarkById(bookmarkId);
      if (currentBookmark == null) {
        throw BookmarkException('Bookmark not found', code: 'NOT_FOUND');
      }

      // Create updated bookmark
      final updatedBookmark = currentBookmark.copyWith(note: note);
      
      // Update local database immediately
      await _repository.updateBookmark(updatedBookmark);
      await _repository.markBookmarkAsUnsynced(bookmarkId);

      // If online, try to sync with server
      if (_connectivityService.hasConnectivity()) {
        try {
          final request = UpdateBookmarkRequest(note: note);
          final serverBookmark = await _apiService.updateBookmark(bookmarkId, request);
          
          // Mark as synced
          await _repository.markBookmarkAsSynced(bookmarkId);
          
          _bookmarkEventsController.add(BookmarkEvent.updated(serverBookmark));
          return serverBookmark;
        } catch (e) {
          // If server request fails, queue for offline processing
          await _jobQueueService.addJob(JobType.updateBookmark, {
            'bookmark_id': bookmarkId,
            'note': note,
          });
        }
      } else {
        // Queue for offline processing
        await _jobQueueService.addJob(JobType.updateBookmark, {
          'bookmark_id': bookmarkId,
          'note': note,
        });
      }

      _bookmarkEventsController.add(BookmarkEvent.updated(updatedBookmark));
      return updatedBookmark;
    } catch (e) {
      throw BookmarkException('Failed to update bookmark: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Delete a bookmark
  Future<void> deleteBookmark(String bookmarkId) async {
    try {
      // Get bookmark before deletion for event notification
      final bookmark = await _repository.getBookmarkById(bookmarkId);
      
      // Delete from local database immediately
      await _repository.deleteBookmark(bookmarkId);

      // If online, try to sync with server
      if (_connectivityService.hasConnectivity()) {
        try {
          await _apiService.deleteBookmark(bookmarkId);
        } catch (e) {
          // If server request fails, queue for offline processing
          await _jobQueueService.addJob(JobType.deleteBookmark, {
            'bookmark_id': bookmarkId,
          });
        }
      } else {
        // Queue for offline processing
        await _jobQueueService.addJob(JobType.deleteBookmark, {
          'bookmark_id': bookmarkId,
        });
      }

      if (bookmark != null) {
        _bookmarkEventsController.add(BookmarkEvent.deleted(bookmark));
      }
    } catch (e) {
      throw BookmarkException('Failed to delete bookmark: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Check if a bookmark exists at a specific page
  Future<bool> hasBookmarkAtPage(String documentId, int pageNumber) async {
    try {
      return await _repository.hasBookmarkAtPage(documentId, pageNumber);
    } catch (e) {
      throw BookmarkException('Failed to check bookmark: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get bookmark at a specific page
  Future<Bookmark?> getBookmarkAtPage(String documentId, int pageNumber) async {
    try {
      return await _repository.getBookmarkAtPage(documentId, pageNumber);
    } catch (e) {
      throw BookmarkException('Failed to get bookmark: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get bookmarks count for a document
  Future<int> getBookmarksCount(String documentId) async {
    try {
      return await _repository.getBookmarksCountByDocumentId(documentId);
    } catch (e) {
      throw BookmarkException('Failed to get bookmarks count: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Process offline bookmark actions
  Future<void> processOfflineActions() async {
    if (!_connectivityService.hasConnectivity()) {
      return; // Skip if offline
    }

    try {
      final pendingJobs = await _jobQueueService.getPendingJobs();
      final bookmarkJobs = pendingJobs.where((job) => 
        job.type == JobType.createBookmark ||
        job.type == JobType.updateBookmark ||
        job.type == JobType.deleteBookmark
      ).toList();

      for (final job in bookmarkJobs) {
        try {
          await _jobQueueService.updateJobStatus(job.id, JobStatus.processing);
          
          switch (job.type) {
            case JobType.createBookmark:
              await _processCreateBookmarkJob(job);
              break;
            case JobType.updateBookmark:
              await _processUpdateBookmarkJob(job);
              break;
            case JobType.deleteBookmark:
              await _processDeleteBookmarkJob(job);
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

  /// Sync server bookmarks to local database
  Future<void> _syncBookmarksToLocal(List<Bookmark> serverBookmarks) async {
    for (final bookmark in serverBookmarks) {
      await _repository.insertBookmark(bookmark);
      await _repository.markBookmarkAsSynced(bookmark.id);
    }
  }

  /// Process create bookmark job
  Future<void> _processCreateBookmarkJob(Job job) async {
    final payload = job.payload;
    final request = CreateBookmarkRequest(
      pageNumber: payload['page_number'] as int,
      note: payload['note'] as String?,
    );
    
    final serverBookmark = await _apiService.addBookmark(
      payload['document_id'] as String,
      request,
    );
    
    // Update local bookmark with server ID
    final localBookmarkId = payload['bookmark_id'] as String;
    await _repository.deleteBookmark(localBookmarkId); // Remove old local bookmark
    await _repository.insertBookmark(serverBookmark);
    await _repository.markBookmarkAsSynced(serverBookmark.id);
  }

  /// Process update bookmark job
  Future<void> _processUpdateBookmarkJob(Job job) async {
    final payload = job.payload;
    final request = UpdateBookmarkRequest(note: payload['note'] as String?);
    
    await _apiService.updateBookmark(payload['bookmark_id'] as String, request);
    await _repository.markBookmarkAsSynced(payload['bookmark_id'] as String);
  }

  /// Process delete bookmark job
  Future<void> _processDeleteBookmarkJob(Job job) async {
    final payload = job.payload;
    await _apiService.deleteBookmark(payload['bookmark_id'] as String);
    // Local bookmark should already be deleted
  }

  /// Dispose resources
  void dispose() {
    _bookmarksController.close();
    _bookmarkEventsController.close();
  }
}

/// Event types for bookmark operations
enum BookmarkEventType { created, updated, deleted }

/// Event model for bookmark operations
class BookmarkEvent {
  final BookmarkEventType type;
  final Bookmark bookmark;
  final DateTime timestamp;

  BookmarkEvent._(this.type, this.bookmark) : timestamp = DateTime.now();

  factory BookmarkEvent.created(Bookmark bookmark) => BookmarkEvent._(BookmarkEventType.created, bookmark);
  factory BookmarkEvent.updated(Bookmark bookmark) => BookmarkEvent._(BookmarkEventType.updated, bookmark);
  factory BookmarkEvent.deleted(Bookmark bookmark) => BookmarkEvent._(BookmarkEventType.deleted, bookmark);
}