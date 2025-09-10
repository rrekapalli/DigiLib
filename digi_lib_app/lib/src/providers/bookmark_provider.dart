import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/bookmark.dart';
import '../services/bookmark_service.dart';

/// Provider for bookmark service
final bookmarkServiceProvider = Provider<BookmarkService>((ref) {
  throw UnimplementedError('BookmarkService provider must be overridden');
});

/// Provider for bookmarks of a specific document
final documentBookmarksProvider = FutureProvider.family<List<Bookmark>, String>((ref, documentId) async {
  final bookmarkService = ref.watch(bookmarkServiceProvider);
  return bookmarkService.getBookmarks(documentId);
});

/// Provider for bookmark at a specific page
final bookmarkAtPageProvider = FutureProvider.family<Bookmark?, ({String documentId, int pageNumber})>((ref, params) async {
  final bookmarkService = ref.watch(bookmarkServiceProvider);
  return bookmarkService.getBookmarkAtPage(params.documentId, params.pageNumber);
});

/// Provider for checking if bookmark exists at page
final hasBookmarkAtPageProvider = FutureProvider.family<bool, ({String documentId, int pageNumber})>((ref, params) async {
  final bookmarkService = ref.watch(bookmarkServiceProvider);
  return bookmarkService.hasBookmarkAtPage(params.documentId, params.pageNumber);
});

/// Provider for bookmark count of a document
final bookmarkCountProvider = FutureProvider.family<int, String>((ref, documentId) async {
  final bookmarkService = ref.watch(bookmarkServiceProvider);
  return bookmarkService.getBookmarksCount(documentId);
});

/// Notifier for managing bookmark operations
class BookmarkNotifier extends StateNotifier<AsyncValue<void>> {
  final BookmarkService _bookmarkService;
  final Ref _ref;

  BookmarkNotifier(this._bookmarkService, this._ref) : super(const AsyncValue.data(null));

  /// Add a bookmark
  Future<void> addBookmark(String documentId, int pageNumber, String userId, {String? note}) async {
    state = const AsyncValue.loading();
    try {
      await _bookmarkService.addBookmark(documentId, pageNumber, userId, note: note);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers to refresh UI
      _ref.invalidate(documentBookmarksProvider(documentId));
      _ref.invalidate(bookmarkAtPageProvider((documentId: documentId, pageNumber: pageNumber)));
      _ref.invalidate(hasBookmarkAtPageProvider((documentId: documentId, pageNumber: pageNumber)));
      _ref.invalidate(bookmarkCountProvider(documentId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update a bookmark
  Future<void> updateBookmark(String bookmarkId, String documentId, {String? note}) async {
    state = const AsyncValue.loading();
    try {
      await _bookmarkService.updateBookmark(bookmarkId, note: note);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers to refresh UI
      _ref.invalidate(documentBookmarksProvider(documentId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete a bookmark
  Future<void> deleteBookmark(String bookmarkId, String documentId) async {
    state = const AsyncValue.loading();
    try {
      await _bookmarkService.deleteBookmark(bookmarkId);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers to refresh UI
      _ref.invalidate(documentBookmarksProvider(documentId));
      _ref.invalidate(bookmarkCountProvider(documentId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for bookmark operations
final bookmarkNotifierProvider = StateNotifierProvider<BookmarkNotifier, AsyncValue<void>>((ref) {
  final bookmarkService = ref.watch(bookmarkServiceProvider);
  return BookmarkNotifier(bookmarkService, ref);
});