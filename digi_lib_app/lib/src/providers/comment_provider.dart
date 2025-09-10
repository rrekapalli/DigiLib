import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/comment.dart';
import '../models/ui/text_selection_anchor.dart';
import '../services/comment_service.dart';

/// Provider for comment service
final commentServiceProvider = Provider<CommentService>((ref) {
  throw UnimplementedError('CommentService provider must be overridden');
});

/// Provider for comments of a specific document
final documentCommentsProvider = FutureProvider.family<List<Comment>, String>((ref, documentId) async {
  final commentService = ref.watch(commentServiceProvider);
  return commentService.getComments(documentId);
});

/// Provider for comments of a specific page
final pageCommentsProvider = FutureProvider.family<List<Comment>, ({String documentId, int pageNumber})>((ref, params) async {
  final commentService = ref.watch(commentServiceProvider);
  return commentService.getComments(params.documentId, pageNumber: params.pageNumber);
});

/// Provider for comment count of a document
final commentCountProvider = FutureProvider.family<int, String>((ref, documentId) async {
  final commentService = ref.watch(commentServiceProvider);
  return commentService.getCommentsCount(documentId);
});

/// Provider for comment count of a specific page
final pageCommentCountProvider = FutureProvider.family<int, ({String documentId, int pageNumber})>((ref, params) async {
  final commentService = ref.watch(commentServiceProvider);
  return commentService.getPageCommentsCount(params.documentId, params.pageNumber);
});

/// Provider for comments with anchors (text selection comments)
final anchoredCommentsProvider = FutureProvider.family<List<Comment>, ({String documentId, int pageNumber})>((ref, params) async {
  final commentService = ref.watch(commentServiceProvider);
  return commentService.getCommentsWithAnchors(params.documentId, params.pageNumber);
});

/// Provider for searching comments
final commentSearchProvider = FutureProvider.family<List<Comment>, ({String query, String? documentId})>((ref, params) async {
  final commentService = ref.watch(commentServiceProvider);
  return commentService.searchComments(params.query, documentId: params.documentId);
});

/// Notifier for managing comment operations
class CommentNotifier extends StateNotifier<AsyncValue<void>> {
  final CommentService _commentService;
  final Ref _ref;

  CommentNotifier(this._commentService, this._ref) : super(const AsyncValue.data(null));

  /// Add a comment
  Future<void> addComment(
    String documentId,
    int pageNumber,
    String content,
    String userId, {
    TextSelectionAnchor? anchor,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _commentService.addComment(
        documentId,
        pageNumber,
        content,
        userId,
        anchor: anchor,
      );
      state = const AsyncValue.data(null);
      
      // Invalidate related providers to refresh UI
      _ref.invalidate(documentCommentsProvider(documentId));
      _ref.invalidate(pageCommentsProvider((documentId: documentId, pageNumber: pageNumber)));
      _ref.invalidate(commentCountProvider(documentId));
      _ref.invalidate(pageCommentCountProvider((documentId: documentId, pageNumber: pageNumber)));
      if (anchor != null) {
        _ref.invalidate(anchoredCommentsProvider((documentId: documentId, pageNumber: pageNumber)));
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update a comment
  Future<void> updateComment(String commentId, String content, String documentId) async {
    state = const AsyncValue.loading();
    try {
      await _commentService.updateComment(commentId, content);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers to refresh UI
      _ref.invalidate(documentCommentsProvider(documentId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId, String documentId) async {
    state = const AsyncValue.loading();
    try {
      await _commentService.deleteComment(commentId);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers to refresh UI
      _ref.invalidate(documentCommentsProvider(documentId));
      _ref.invalidate(commentCountProvider(documentId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for comment operations
final commentNotifierProvider = StateNotifierProvider<CommentNotifier, AsyncValue<void>>((ref) {
  final commentService = ref.watch(commentServiceProvider);
  return CommentNotifier(commentService, ref);
});