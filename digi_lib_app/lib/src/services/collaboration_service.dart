import 'dart:async';
import '../models/entities/share.dart';
import '../models/entities/document.dart';
import '../models/entities/bookmark.dart';
import '../models/entities/comment.dart';
import 'share_service.dart';
import 'document_service.dart';
import 'bookmark_service.dart';
import 'comment_service.dart';

/// Exception thrown when collaboration operations fail
class CollaborationException implements Exception {
  final String message;
  final String? code;
  final Exception? cause;

  const CollaborationException(this.message, {this.code, this.cause});

  @override
  String toString() => 'CollaborationException: $message';
}

/// Service for managing collaborative features and access control
class CollaborationService {
  final ShareService _shareService;
  final DocumentService _documentService;
  final BookmarkService _bookmarkService;
  final CommentService _commentService;

  // Stream controllers for collaboration events
  final StreamController<CollaborationEvent> _collaborationEventsController = 
      StreamController<CollaborationEvent>.broadcast();

  CollaborationService({
    required ShareService shareService,
    required DocumentService documentService,
    required BookmarkService bookmarkService,
    required CommentService commentService,
  }) : _shareService = shareService,
       _documentService = documentService,
       _bookmarkService = bookmarkService,
       _commentService = commentService;

  /// Stream of collaboration events
  Stream<CollaborationEvent> get collaborationEventsStream => _collaborationEventsController.stream;

  /// Check if user has access to a document
  Future<bool> hasDocumentAccess(String documentId, String userEmail, String ownerId) async {
    try {
      // Owner always has access
      if (await _isDocumentOwner(documentId, ownerId)) {
        return true;
      }

      // Check if document is shared with user
      return await _shareService.isSharedWithUser(documentId, userEmail);
    } catch (e) {
      throw CollaborationException('Failed to check document access: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get user's permission level for a document
  Future<SharePermission?> getDocumentPermission(String documentId, String userEmail, String ownerId) async {
    try {
      // Owner has full permission
      if (await _isDocumentOwner(documentId, ownerId)) {
        return SharePermission.full;
      }

      // Get shared permission
      return await _shareService.getSharePermission(documentId, userEmail);
    } catch (e) {
      throw CollaborationException('Failed to get document permission: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Check if user can view a document
  Future<bool> canViewDocument(String documentId, String userEmail, String ownerId) async {
    try {
      return await _shareService.hasPermission(documentId, userEmail, SharePermission.view) ||
             await _isDocumentOwner(documentId, ownerId);
    } catch (e) {
      return false; // Deny access on error
    }
  }

  /// Check if user can comment on a document
  Future<bool> canCommentOnDocument(String documentId, String userEmail, String ownerId) async {
    try {
      return await _shareService.hasPermission(documentId, userEmail, SharePermission.comment) ||
             await _isDocumentOwner(documentId, ownerId);
    } catch (e) {
      return false; // Deny access on error
    }
  }

  /// Check if user can edit/manage a document
  Future<bool> canEditDocument(String documentId, String userEmail, String ownerId) async {
    try {
      return await _shareService.hasPermission(documentId, userEmail, SharePermission.full) ||
             await _isDocumentOwner(documentId, ownerId);
    } catch (e) {
      return false; // Deny access on error
    }
  }

  /// Get shared documents accessible to a user
  Future<List<Document>> getSharedDocuments(String userEmail) async {
    try {
      final sharedWithMe = await _shareService.getSharedWithMe(userEmail);
      final documentIds = sharedWithMe
          .where((share) => share.subjectType == ShareSubjectType.document)
          .map((share) => share.subjectId)
          .toList();

      final documents = <Document>[];
      for (final documentId in documentIds) {
        try {
          final document = await _documentService.getDocument(documentId);
          if (document != null) {
            documents.add(document);
          }
        } catch (e) {
          // Skip documents that can't be accessed
          continue;
        }
      }

      return documents;
    } catch (e) {
      throw CollaborationException('Failed to get shared documents: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get visible bookmarks for a document based on user permissions
  Future<List<Bookmark>> getVisibleBookmarks(String documentId, String userEmail, String ownerId) async {
    try {
      final permission = await getDocumentPermission(documentId, userEmail, ownerId);
      if (permission == null) {
        return []; // No access
      }

      final allBookmarks = await _bookmarkService.getBookmarks(documentId);
      
      // Filter bookmarks based on permission and ownership
      return allBookmarks.where((bookmark) {
        // User can see their own bookmarks
        if (bookmark.userId == userEmail) return true;
        
        // With comment or full permission, user can see shared bookmarks
        if (permission == SharePermission.comment || permission == SharePermission.full) {
          return true;
        }
        
        // With view permission, user can only see their own bookmarks
        return false;
      }).toList();
    } catch (e) {
      throw CollaborationException('Failed to get visible bookmarks: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get visible comments for a document based on user permissions
  Future<List<Comment>> getVisibleComments(String documentId, String userEmail, String ownerId, {int? pageNumber}) async {
    try {
      final permission = await getDocumentPermission(documentId, userEmail, ownerId);
      if (permission == null) {
        return []; // No access
      }

      final allComments = await _commentService.getComments(documentId, pageNumber: pageNumber);
      
      // Filter comments based on permission and ownership
      return allComments.where((comment) {
        // User can see their own comments
        if (comment.userId == userEmail) return true;
        
        // With comment or full permission, user can see all comments
        if (permission == SharePermission.comment || permission == SharePermission.full) {
          return true;
        }
        
        // With view permission, user can only see their own comments
        return false;
      }).toList();
    } catch (e) {
      throw CollaborationException('Failed to get visible comments: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Create a bookmark with permission validation
  Future<Bookmark> createBookmarkWithPermission(
    String documentId, 
    int pageNumber, 
    String userId, 
    String ownerId,
    {String? note}
  ) async {
    try {
      // Check if user has at least view permission
      if (!await canViewDocument(documentId, userId, ownerId)) {
        throw CollaborationException('Insufficient permissions to create bookmark', code: 'PERMISSION_DENIED');
      }

      final bookmark = await _bookmarkService.addBookmark(documentId, pageNumber, userId, note: note);
      
      _collaborationEventsController.add(CollaborationEvent.bookmarkCreated(
        documentId: documentId,
        userId: userId,
        bookmark: bookmark,
      ));
      
      return bookmark;
    } catch (e) {
      throw CollaborationException('Failed to create bookmark: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Create a comment with permission validation
  Future<Comment> createCommentWithPermission(
    String documentId,
    int pageNumber,
    String content,
    String userId,
    String ownerId,
    {Map<String, dynamic>? anchor}
  ) async {
    try {
      // Check if user has comment permission
      if (!await canCommentOnDocument(documentId, userId, ownerId)) {
        throw CollaborationException('Insufficient permissions to create comment', code: 'PERMISSION_DENIED');
      }

      final comment = await _commentService.addComment(
        documentId, 
        pageNumber, 
        content, 
        userId,
        anchor: anchor,
      );
      
      _collaborationEventsController.add(CollaborationEvent.commentCreated(
        documentId: documentId,
        userId: userId,
        comment: comment,
      ));
      
      return comment;
    } catch (e) {
      throw CollaborationException('Failed to create comment: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Update a comment with permission validation
  Future<Comment> updateCommentWithPermission(
    String commentId,
    String content,
    String userId,
    String ownerId,
    String documentId,
  ) async {
    try {
      // Get the comment to check ownership
      final existingComment = await _commentService.getComment(commentId);
      if (existingComment == null) {
        throw CollaborationException('Comment not found', code: 'NOT_FOUND');
      }

      // User can only edit their own comments, or owner can edit any comment
      final canEdit = existingComment.userId == userId || await _isDocumentOwner(documentId, ownerId);
      if (!canEdit) {
        throw CollaborationException('Insufficient permissions to edit comment', code: 'PERMISSION_DENIED');
      }

      final updatedComment = await _commentService.updateComment(commentId, content);
      
      _collaborationEventsController.add(CollaborationEvent.commentUpdated(
        documentId: documentId,
        userId: userId,
        comment: updatedComment,
      ));
      
      return updatedComment;
    } catch (e) {
      throw CollaborationException('Failed to update comment: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Delete a comment with permission validation
  Future<void> deleteCommentWithPermission(
    String commentId,
    String userId,
    String ownerId,
    String documentId,
  ) async {
    try {
      // Get the comment to check ownership
      final existingComment = await _commentService.getComment(commentId);
      if (existingComment == null) {
        throw CollaborationException('Comment not found', code: 'NOT_FOUND');
      }

      // User can only delete their own comments, or owner can delete any comment
      final canDelete = existingComment.userId == userId || await _isDocumentOwner(documentId, ownerId);
      if (!canDelete) {
        throw CollaborationException('Insufficient permissions to delete comment', code: 'PERMISSION_DENIED');
      }

      await _commentService.deleteComment(commentId);
      
      _collaborationEventsController.add(CollaborationEvent.commentDeleted(
        documentId: documentId,
        userId: userId,
        comment: existingComment,
      ));
    } catch (e) {
      throw CollaborationException('Failed to delete comment: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Send share invitation notification (placeholder for notification system)
  Future<void> sendShareInvitation(Share share, String inviterName) async {
    try {
      // This would integrate with a notification service
      // For now, we'll emit an event that the UI can handle
      _collaborationEventsController.add(CollaborationEvent.shareInvitationSent(
        share: share,
        inviterName: inviterName,
      ));
      
      // TODO: Implement actual notification sending (email, push notification, etc.)
      // This could integrate with services like:
      // - Email service for email notifications
      // - Push notification service for mobile notifications
      // - In-app notification system
      
    } catch (e) {
      throw CollaborationException('Failed to send share invitation: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get collaboration activity for a document
  Future<List<CollaborationActivity>> getDocumentActivity(String documentId, String userEmail, String ownerId) async {
    try {
      if (!await canViewDocument(documentId, userEmail, ownerId)) {
        throw CollaborationException('Insufficient permissions to view activity', code: 'PERMISSION_DENIED');
      }

      final activities = <CollaborationActivity>[];
      
      // Get recent bookmarks
      final bookmarks = await getVisibleBookmarks(documentId, userEmail, ownerId);
      for (final bookmark in bookmarks.take(10)) { // Limit to recent 10
        activities.add(CollaborationActivity(
          type: CollaborationActivityType.bookmarkCreated,
          userId: bookmark.userId,
          timestamp: bookmark.createdAt,
          documentId: documentId,
          description: 'Added bookmark on page ${bookmark.pageNumber}',
        ));
      }
      
      // Get recent comments
      final comments = await getVisibleComments(documentId, userEmail, ownerId);
      for (final comment in comments.take(10)) { // Limit to recent 10
        activities.add(CollaborationActivity(
          type: CollaborationActivityType.commentCreated,
          userId: comment.userId ?? 'Unknown',
          timestamp: comment.createdAt,
          documentId: documentId,
          description: 'Added comment on page ${comment.pageNumber}',
        ));
      }
      
      // Sort by timestamp (most recent first)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return activities.take(20).toList(); // Return top 20 activities
    } catch (e) {
      throw CollaborationException('Failed to get document activity: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Check if user is the owner of a document
  Future<bool> _isDocumentOwner(String documentId, String ownerId) async {
    try {
      final document = await _documentService.getDocument(documentId);
      // This would need to be implemented based on how document ownership is tracked
      // For now, we'll use the provided ownerId parameter
      return document != null; // Placeholder logic
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _collaborationEventsController.close();
  }
}

/// Event types for collaboration operations
enum CollaborationEventType { 
  bookmarkCreated, 
  commentCreated, 
  commentUpdated, 
  commentDeleted, 
  shareInvitationSent 
}

/// Event model for collaboration operations
class CollaborationEvent {
  final CollaborationEventType type;
  final String documentId;
  final String userId;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  CollaborationEvent._({
    required this.type,
    required this.documentId,
    required this.userId,
    required this.data,
  }) : timestamp = DateTime.now();

  factory CollaborationEvent.bookmarkCreated({
    required String documentId,
    required String userId,
    required Bookmark bookmark,
  }) => CollaborationEvent._(
    type: CollaborationEventType.bookmarkCreated,
    documentId: documentId,
    userId: userId,
    data: {'bookmark': bookmark},
  );

  factory CollaborationEvent.commentCreated({
    required String documentId,
    required String userId,
    required Comment comment,
  }) => CollaborationEvent._(
    type: CollaborationEventType.commentCreated,
    documentId: documentId,
    userId: userId,
    data: {'comment': comment},
  );

  factory CollaborationEvent.commentUpdated({
    required String documentId,
    required String userId,
    required Comment comment,
  }) => CollaborationEvent._(
    type: CollaborationEventType.commentUpdated,
    documentId: documentId,
    userId: userId,
    data: {'comment': comment},
  );

  factory CollaborationEvent.commentDeleted({
    required String documentId,
    required String userId,
    required Comment comment,
  }) => CollaborationEvent._(
    type: CollaborationEventType.commentDeleted,
    documentId: documentId,
    userId: userId,
    data: {'comment': comment},
  );

  factory CollaborationEvent.shareInvitationSent({
    required Share share,
    required String inviterName,
  }) => CollaborationEvent._(
    type: CollaborationEventType.shareInvitationSent,
    documentId: share.subjectId,
    userId: share.ownerId,
    data: {'share': share, 'inviter_name': inviterName},
  );
}

/// Activity types for collaboration tracking
enum CollaborationActivityType {
  bookmarkCreated,
  commentCreated,
  commentUpdated,
  commentDeleted,
  shareCreated,
}

/// Model for collaboration activity
class CollaborationActivity {
  final CollaborationActivityType type;
  final String userId;
  final DateTime timestamp;
  final String documentId;
  final String description;

  const CollaborationActivity({
    required this.type,
    required this.userId,
    required this.timestamp,
    required this.documentId,
    required this.description,
  });
}