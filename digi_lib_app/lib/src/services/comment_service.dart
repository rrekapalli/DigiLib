import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/entities/comment.dart';
import '../models/api/create_comment_request.dart';
import '../models/api/update_comment_request.dart';
import '../models/ui/text_selection_anchor.dart';
import '../database/repositories/comment_repository.dart';
import '../network/connectivity_service.dart';
import 'comment_api_service.dart';
import 'job_queue_service.dart';

/// Exception thrown when comment operations fail
class CommentException implements Exception {
  final String message;
  final String? code;
  final Exception? cause;

  const CommentException(this.message, {this.code, this.cause});

  @override
  String toString() => 'CommentException: $message';
}

/// Service for managing comments with API integration, local caching, and offline support
class CommentService {
  final CommentApiService _apiService;
  final CommentRepository _repository;
  final JobQueueService _jobQueueService;
  final ConnectivityService _connectivityService;
  final Uuid _uuid = const Uuid();

  // Stream controllers for real-time updates
  final StreamController<List<Comment>> _commentsController =
      StreamController<List<Comment>>.broadcast();
  final StreamController<CommentEvent> _commentEventsController =
      StreamController<CommentEvent>.broadcast();

  CommentService({
    required CommentApiService apiService,
    required CommentRepository repository,
    required JobQueueService jobQueueService,
    required ConnectivityService connectivityService,
  }) : _apiService = apiService,
       _repository = repository,
       _jobQueueService = jobQueueService,
       _connectivityService = connectivityService;

  /// Stream of comment lists (for UI updates)
  Stream<List<Comment>> get commentsStream => _commentsController.stream;

  /// Stream of comment events (create, update, delete)
  Stream<CommentEvent> get commentEventsStream =>
      _commentEventsController.stream;

  /// Get all comments for a specific document
  Future<List<Comment>> getComments(
    String documentId, {
    int? pageNumber,
  }) async {
    try {
      // Always return local data first for immediate UI response
      final localComments = pageNumber != null
          ? await _repository.getCommentsByDocumentAndPage(
              documentId,
              pageNumber,
            )
          : await _repository.getCommentsByDocumentId(documentId);

      // If online, try to sync with server
      if (_connectivityService.isConnected) {
        try {
          final serverComments = await _apiService.getComments(
            documentId,
            pageNumber: pageNumber,
          );

          // Update local cache with server data
          await _syncCommentsToLocal(serverComments);

          // Return updated local data
          final updatedComments = pageNumber != null
              ? await _repository.getCommentsByDocumentAndPage(
                  documentId,
                  pageNumber,
                )
              : await _repository.getCommentsByDocumentId(documentId);
          _commentsController.add(updatedComments);
          return updatedComments;
        } catch (e) {
          // If server request fails, continue with local data
          // Log the error but don't throw to maintain offline functionality
        }
      }

      _commentsController.add(localComments);
      return localComments;
    } catch (e) {
      throw CommentException(
        'Failed to get comments: ${e.toString()}',
        cause: e is Exception ? e : null,
      );
    }
  }

  /// Get a specific comment by ID
  Future<Comment?> getComment(String commentId) async {
    try {
      // Try to get from local database first
      final localComment = await _repository.getCommentById(commentId);

      // If online and comment not found locally, try server
      if (localComment == null &&
          _connectivityService.hasConnectivity()) {
        try {
          final serverComment = await _apiService.getComment(commentId);

          // Cache the comment locally
          await _repository.insertComment(serverComment);
          await _repository.markCommentAsSynced(serverComment.id);

          return serverComment;
        } catch (e) {
          // If server request fails, return null
          return null;
        }
      }

      return localComment;
    } catch (e) {
      throw CommentException(
        'Failed to get comment: ${e.toString()}',
        cause: e is Exception ? e : null,
      );
    }
  }

  /// Add a new comment
  Future<Comment> addComment(
    String documentId,
    int pageNumber,
    String content,
    String userId, {
    TextSelectionAnchor? anchor,
  }) async {
    try {
      // Create comment with local ID
      final comment = Comment(
        id: _uuid.v4(),
        docId: documentId,
        userId: userId,
        pageNumber: pageNumber,
        content: content,
        anchor: anchor?.toJson(),
        createdAt: DateTime.now(),
      );

      // Save to local database immediately
      await _repository.insertComment(comment);

      // If online, try to sync with server
      if (_connectivityService.isConnected) {
        try {
          final request = CreateCommentRequest(
            pageNumber: pageNumber,
            content: content,
            anchor: anchor?.toJson(),
          );
          final serverComment = await _apiService.addComment(
            documentId,
            request,
          );

          // Update local comment with server ID and mark as synced
          final updatedComment = comment.copyWith(id: serverComment.id);
          await _repository.updateComment(updatedComment);
          await _repository.markCommentAsSynced(serverComment.id);

          _commentEventsController.add(CommentEvent.created(updatedComment));
          return updatedComment;
        } catch (e) {
          // If server request fails, queue for offline processing
          await _jobQueueService.addJob(JobType.createComment, {
            'comment_id': comment.id,
            'document_id': documentId,
            'page_number': pageNumber,
            'content': content,
            'anchor': anchor?.toJson(),
            'user_id': userId,
          });
        }
      } else {
        // Queue for offline processing
        await _jobQueueService.addJob(JobType.createComment, {
          'comment_id': comment.id,
          'document_id': documentId,
          'page_number': pageNumber,
          'content': content,
          'anchor': anchor?.toJson(),
          'user_id': userId,
        });
      }

      _commentEventsController.add(CommentEvent.created(comment));
      return comment;
    } catch (e) {
      throw CommentException(
        'Failed to add comment: ${e.toString()}',
        cause: e is Exception ? e : null,
      );
    }
  }

  /// Update an existing comment
  Future<Comment> updateComment(String commentId, String content) async {
    try {
      // Get current comment from local database
      final currentComment = await _repository.getCommentById(commentId);
      if (currentComment == null) {
        throw CommentException('Comment not found', code: 'NOT_FOUND');
      }

      // Create updated comment
      final updatedComment = currentComment.copyWith(content: content);

      // Update local database immediately
      await _repository.updateComment(updatedComment);
      await _repository.markCommentAsUnsynced(commentId);

      // If online, try to sync with server
      if (_connectivityService.isConnected) {
        try {
          final request = UpdateCommentRequest(content: content);
          final serverComment = await _apiService.updateComment(
            commentId,
            request,
          );

          // Mark as synced
          await _repository.markCommentAsSynced(commentId);

          _commentEventsController.add(CommentEvent.updated(serverComment));
          return serverComment;
        } catch (e) {
          // If server request fails, queue for offline processing
          await _jobQueueService.addJob(JobType.updateComment, {
            'comment_id': commentId,
            'content': content,
          });
        }
      } else {
        // Queue for offline processing
        await _jobQueueService.addJob(JobType.updateComment, {
          'comment_id': commentId,
          'content': content,
        });
      }

      _commentEventsController.add(CommentEvent.updated(updatedComment));
      return updatedComment;
    } catch (e) {
      throw CommentException(
        'Failed to update comment: ${e.toString()}',
        cause: e is Exception ? e : null,
      );
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      // Get comment before deletion for event notification
      final comment = await _repository.getCommentById(commentId);

      // Delete from local database immediately
      await _repository.deleteComment(commentId);

      // If online, try to sync with server
      if (_connectivityService.isConnected) {
        try {
          await _apiService.deleteComment(commentId);
        } catch (e) {
          // If server request fails, queue for offline processing
          await _jobQueueService.addJob(JobType.deleteComment, {
            'comment_id': commentId,
          });
        }
      } else {
        // Queue for offline processing
        await _jobQueueService.addJob(JobType.deleteComment, {
          'comment_id': commentId,
        });
      }

      if (comment != null) {
        _commentEventsController.add(CommentEvent.deleted(comment));
      }
    } catch (e) {
      throw CommentException(
        'Failed to delete comment: ${e.toString()}',
        cause: e is Exception ? e : null,
      );
    }
  }

  /// Get comments count for a document
  Future<int> getCommentsCount(String documentId) async {
    try {
      return await _repository.getCommentsCountByDocumentId(documentId);
    } catch (e) {
      throw CommentException(
        'Failed to get comments count: ${e.toString()}',
        cause: e is Exception ? e : null,
      );
    }
  }

  /// Get comments count for a specific page
  Future<int> getPageCommentsCount(String documentId, int pageNumber) async {
    try {
      return await _repository.getCommentsCountByPage(documentId, pageNumber);
    } catch (e) {
      throw CommentException(
        'Failed to get page comments count: ${e.toString()}',
        cause: e is Exception ? e : null,
      );
    }
  }

  /// Search comments by content
  Future<List<Comment>> searchComments(
    String query, {
    String? documentId,
  }) async {
    try {
      // Search local database first
      final localResults = await _repository.searchComments(
        query,
        documentId: documentId,
      );

      // If online, also search server
      if (_connectivityService.isConnected) {
        try {
          final serverResults = await _apiService.searchComments(
            query,
            documentId: documentId,
          );

          // Merge and deduplicate results
          final allResults = <String, Comment>{};
          for (final comment in localResults) {
            allResults[comment.id] = comment;
          }
          for (final comment in serverResults) {
            allResults[comment.id] = comment;
          }

          return allResults.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        } catch (e) {
          // If server search fails, return local results
        }
      }

      return localResults;
    } catch (e) {
      throw CommentException(
        'Failed to search comments: ${e.toString()}',
        cause: e is Exception ? e : null,
      );
    }
  }

  /// Get comments with anchor data (for text selection comments)
  Future<List<Comment>> getCommentsWithAnchors(
    String documentId,
    int pageNumber,
  ) async {
    try {
      return await _repository.getCommentsWithAnchors(documentId, pageNumber);
    } catch (e) {
      throw CommentException(
        'Failed to get anchored comments: ${e.toString()}',
        cause: e is Exception ? e : null,
      );
    }
  }

  /// Process offline comment actions
  Future<void> processOfflineActions() async {
    if (!_connectivityService.isConnected) {
      return; // Skip if offline
    }

    try {
      final pendingJobs = await _jobQueueService.getPendingJobs();
      final commentJobs = pendingJobs
          .where(
            (job) =>
                job.type == JobType.createComment ||
                job.type == JobType.updateComment ||
                job.type == JobType.deleteComment,
          )
          .toList();

      for (final job in commentJobs) {
        try {
          await _jobQueueService.updateJobStatus(job.id, JobStatus.processing);

          switch (job.type) {
            case JobType.createComment:
              await _processCreateCommentJob(job);
              break;
            case JobType.updateComment:
              await _processUpdateCommentJob(job);
              break;
            case JobType.deleteComment:
              await _processDeleteCommentJob(job);
              break;
            default:
              continue;
          }

          await _jobQueueService.completeJob(job.id);
        } catch (e) {
          await _jobQueueService.incrementJobAttempts(
            job.id,
            error: e.toString(),
          );

          // Fail job after 3 attempts
          if (job.attempts >= 2) {
            await _jobQueueService.failJob(
              job.id,
              'Max attempts reached: ${e.toString()}',
            );
          }
        }
      }
    } catch (e) {
      // Log error but don't throw to avoid breaking sync process
    }
  }

  /// Sync server comments to local database
  Future<void> _syncCommentsToLocal(List<Comment> serverComments) async {
    for (final comment in serverComments) {
      await _repository.insertComment(comment);
      await _repository.markCommentAsSynced(comment.id);
    }
  }

  /// Process create comment job
  Future<void> _processCreateCommentJob(Job job) async {
    final payload = job.payload;
    final request = CreateCommentRequest(
      pageNumber: payload['page_number'] as int,
      content: payload['content'] as String,
      anchor: payload['anchor'] as Map<String, dynamic>?,
    );

    final serverComment = await _apiService.addComment(
      payload['document_id'] as String,
      request,
    );

    // Update local comment with server ID
    final localCommentId = payload['comment_id'] as String;
    await _repository.deleteComment(localCommentId); // Remove old local comment
    await _repository.insertComment(serverComment);
    await _repository.markCommentAsSynced(serverComment.id);
  }

  /// Process update comment job
  Future<void> _processUpdateCommentJob(Job job) async {
    final payload = job.payload;
    final request = UpdateCommentRequest(content: payload['content'] as String);

    await _apiService.updateComment(payload['comment_id'] as String, request);
    await _repository.markCommentAsSynced(payload['comment_id'] as String);
  }

  /// Process delete comment job
  Future<void> _processDeleteCommentJob(Job job) async {
    final payload = job.payload;
    await _apiService.deleteComment(payload['comment_id'] as String);
    // Local comment should already be deleted
  }

  /// Dispose resources
  void dispose() {
    _commentsController.close();
    _commentEventsController.close();
  }
}

/// Event types for comment operations
enum CommentEventType { created, updated, deleted }

/// Event model for comment operations
class CommentEvent {
  final CommentEventType type;
  final Comment comment;
  final DateTime timestamp;

  CommentEvent._(this.type, this.comment) : timestamp = DateTime.now();

  factory CommentEvent.created(Comment comment) =>
      CommentEvent._(CommentEventType.created, comment);
  factory CommentEvent.updated(Comment comment) =>
      CommentEvent._(CommentEventType.updated, comment);
  factory CommentEvent.deleted(Comment comment) =>
      CommentEvent._(CommentEventType.deleted, comment);
}
